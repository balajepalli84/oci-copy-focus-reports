# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ─────────────────────────────────────────────────────────────────────────────
# iam.tf
#
# No dynamic group is used. The function OCID is referenced directly in every
# policy statement via request.principal.id, which uniquely identifies the
# specific function as the Resource Principal.
#
# Policy sits at tenancy (root) level because the 'endorse' cross-tenancy
# statement is required and can only appear in a root-level policy.
#
# Dependency chain:
#   objectstorage bucket → function (build/push) → policy
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_identity_policy" "focus_reports" {
  compartment_id = var.tenancy_ocid
  name           = var.policy_name
  description    = "Policies for the FOCUS reports automation workflow – scoped to the specific function OCID"

  statements = [
    # ── Cross-tenancy: read FOCUS reports from OCI 'bling' namespace ─────────
    # Oracle hosts cost/usage reports in a fixed tenancy (the 'bling' namespace).
    # The 'define' + 'endorse' pair grants cross-tenancy read access, scoped
    # exclusively to the deployed function's OCID.
    "define tenancy usage-report as ocid1.tenancy.oc1..aaaaaaaaned4fkpkisbwjlr56u7cj63lf3wffbilvqknstgtvzub7vhqkggq",
    "endorse any-user to read objects in tenancy usage-report where request.principal.id = '${oci_functions_function.this.id}'",

    # ── Inspect compartments/tenancies (required by Resource Principal signer) ─
    # oci.auth.signers.get_resource_principals_signer() calls these internally
    # to resolve the tenancy ID for the source bucket lookup.
    "Allow any-user to inspect compartments in tenancy where request.principal.id = '${oci_functions_function.this.id}'",
    "Allow any-user to inspect tenancies in tenancy where request.principal.id = '${oci_functions_function.this.id}'",

    # ── Write FOCUS report files to the destination bucket ────────────────────
    "Allow any-user to manage objects in compartment id ${var.compartment_ocid} where all {request.principal.id = '${oci_functions_function.this.id}', target.bucket.name = '${oci_objectstorage_bucket.focus_reports.name}'}",
    "Allow any-user to read buckets in compartment id ${var.compartment_ocid} where all {request.principal.id = '${oci_functions_function.this.id}', target.bucket.name = '${oci_objectstorage_bucket.focus_reports.name}'}",

    # ── Resource Scheduler → invoke the function ──────────────────────────────
    # Scoped to both the compartment and the specific schedule OCID.
    # oci_resource_scheduler_schedule.this.id is available as a real resource
    # reference now that the schedule is managed natively by Terraform.
    "Allow any-user to manage functions-family in compartment id ${var.compartment_ocid} where all {request.principal.type = 'resourceschedule', request.principal.id = '${oci_resource_scheduler_schedule.this.id}'}",
  ]

  depends_on = [
    oci_functions_function.this,
    oci_objectstorage_bucket.focus_reports,
    oci_resource_scheduler_schedule.this,
  ]

  lifecycle {
    ignore_changes = [defined_tags]
  }
}
