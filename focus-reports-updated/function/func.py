import io
import json
import logging
import os
import gzip
import zipfile
from datetime import datetime, timedelta

import oci
from fdk import response

log = logging.getLogger(__name__)


def clean_tmp_directory(path: str = "/tmp") -> None:
    """Remove all files from /tmp to free ephemeral storage between runs."""
    try:
        if path == "/tmp":
            os.system("rm -rf /tmp/*")
        log.info("Cleaned %s", path)
    except Exception as exc:
        log.warning("Failed to clean %s: %s", path, exc)


def handler(ctx, data: io.BytesIO = None):
    """
    Copy yesterday's FOCUS reports from the OCI-managed 'bling' namespace
    to the configured destination bucket in this tenancy.

    Config is injected by Terraform at the Functions Application level:
        DEST_NAMESPACE  – Object Storage namespace of this tenancy
        DEST_BUCKET     – destination bucket name (e.g. Cost_Usage_Reports)
    """
    processed_files = []

    # ── Read config from environment (set by Terraform) ──────────────────────
    dest_namespace = os.environ.get("DEST_NAMESPACE", "")
    dest_bucket    = os.environ.get("DEST_BUCKET", "Cost_Usage_Reports")

    if not dest_namespace:
        msg = "DEST_NAMESPACE is not set. Check the Functions Application config in Terraform."
        log.error(msg)
        return response.Response(
            ctx,
            response_data=json.dumps({"error": msg}),
            headers={"Content-Type": "application/json"},
            status_code=500,
        )

    try:
        # ── Date prefix: yesterday's reports ─────────────────────────────────
        yesterday   = datetime.utcnow() - timedelta(days=1)
        prefix_file = (
            f"FOCUS Reports/{yesterday.year}/"
            f"{yesterday.strftime('%m')}/"
            f"{yesterday.strftime('%d')}"
        )
        log.info("Listing with prefix: %s", prefix_file)

        destination_path = "/tmp"
        clean_tmp_directory(destination_path)

        # ── Authenticate via Resource Principal ──────────────────────────────
        signer             = oci.auth.signers.get_resource_principals_signer()
        reporting_namespace = "bling"
        reporting_bucket   = signer.tenancy_id   # bucket name = tenancy OCID in 'bling'
        log.info("Source tenancy bucket: %s", reporting_bucket)

        object_storage = oci.object_storage.ObjectStorageClient(config={}, signer=signer)

        # ── List source objects ───────────────────────────────────────────────
        all_objects = oci.pagination.list_call_get_all_results(
            object_storage.list_objects,
            reporting_namespace,
            reporting_bucket,
            prefix=prefix_file,
        )
        found = len(all_objects.data.objects)
        log.info("Found %d file(s) to process", found)

        # ── Process each object ───────────────────────────────────────────────
        for obj in all_objects.data.objects:
            source_path = obj.name                              # e.g. FOCUS Reports/2025/04/05/0001.csv.gz
            filename    = source_path.rsplit("/", 1)[-1]
            local_path  = os.path.join(destination_path, filename)

            # Download to /tmp
            details = object_storage.get_object(reporting_namespace, reporting_bucket, source_path)
            with open(local_path, "wb") as f:
                for chunk in details.data.raw.stream(1024 * 1024, decode_content=False):
                    f.write(chunk)
            log.info("Downloaded: %s", source_path)

            # ── ZIP archive ────────────────────────────────────────────────────
            if zipfile.is_zipfile(local_path):
                with zipfile.ZipFile(local_path, "r") as zf:
                    for name in zf.namelist():
                        extracted_path = os.path.join(destination_path, name)
                        if os.path.isdir(extracted_path):
                            continue
                        os.makedirs(os.path.dirname(extracted_path), exist_ok=True)
                        zf.extract(name, destination_path)
                        dest_path = os.path.join(os.path.dirname(source_path), name)
                        with open(extracted_path, "rb") as ef:
                            object_storage.put_object(
                                namespace_name=dest_namespace,
                                bucket_name=dest_bucket,
                                object_name=dest_path,
                                put_object_body=ef,
                            )
                        processed_files.append(dest_path)
                        log.info("Uploaded (unzipped): %s", dest_path)

            # ── GZIP file ──────────────────────────────────────────────────────
            elif filename.endswith(".gz"):
                unzipped_name = filename[:-3]
                unzipped_path = os.path.join(destination_path, unzipped_name)
                dest_path     = os.path.join(os.path.dirname(source_path), unzipped_name)
                with gzip.open(local_path, "rb") as fin, open(unzipped_path, "wb") as fout:
                    fout.write(fin.read())
                with open(unzipped_path, "rb") as f:
                    object_storage.put_object(
                        namespace_name=dest_namespace,
                        bucket_name=dest_bucket,
                        object_name=dest_path,
                        put_object_body=f,
                    )
                processed_files.append(dest_path)
                log.info("Uploaded (gunzipped): %s", dest_path)

            # ── Pass-through ───────────────────────────────────────────────────
            else:
                with open(local_path, "rb") as f:
                    object_storage.put_object(
                        namespace_name=dest_namespace,
                        bucket_name=dest_bucket,
                        object_name=source_path,
                        put_object_body=f,
                    )
                processed_files.append(source_path)
                log.info("Uploaded: %s", source_path)

    except Exception as exc:
        log.error("Error during processing: %s", exc, exc_info=True)
        return response.Response(
            ctx,
            response_data=json.dumps({"error": str(exc), "files": processed_files}),
            headers={"Content-Type": "application/json"},
            status_code=500,
        )

    return response.Response(
        ctx,
        response_data=json.dumps({
            "message": "Processed files successfully",
            "date":    str(yesterday.date()),
            "count":   len(processed_files),
            "files":   processed_files,
        }),
        headers={"Content-Type": "application/json"},
    )
