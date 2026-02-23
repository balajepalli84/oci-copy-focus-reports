# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ─────────────────────────────────────────────────────────────────────────────
# locals.tf
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # Derive the short 3-letter OCIR region key from the full region name.
  # Used to construct OCIR image URLs: <region_key>.ocir.io/...
  region_key = lower(
    one([
      for r in data.oci_identity_regions.all.regions : r.key
      if r.name == var.region
    ])
  )

  # Read function metadata once from func.yaml so all resources stay in sync
  func_yaml        = yamldecode(file("${var.function_working_dir}/func.yaml"))
  function_name    = local.func_yaml["name"]
  function_version = local.func_yaml["version"]
  function_memory  = try(local.func_yaml["memory"], var.function_memory_in_mbs)
  function_timeout = try(local.func_yaml["timeout"], var.function_timeout_in_seconds)

  # Full OCIR image reference used by oci_functions_function and docker commands
  image_path = "${local.region_key}.ocir.io/${data.oci_objectstorage_namespace.ns.namespace}/${var.repository_name}/${local.function_name}:${local.function_version}"

  # Parse optional function config JSON (falls back to empty map)
  function_config = (
    coalesce(var.function_parameters_json_string, "_EMPTY_") != "_EMPTY_"
    ? { for k, v in jsondecode(var.function_parameters_json_string) : trimspace(k) => trimspace(v) }
    : {}
  )

  # Merge static config (destination bucket/namespace) with any user-supplied config.
  # DEST_BUCKET references the created bucket resource to enforce dependency ordering.
  merged_function_config = merge(
    {
      DEST_NAMESPACE = data.oci_objectstorage_namespace.ns.namespace
      DEST_BUCKET    = oci_objectstorage_bucket.focus_reports.name
    },
    local.function_config
  )
}
