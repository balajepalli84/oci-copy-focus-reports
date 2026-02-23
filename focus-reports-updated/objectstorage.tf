# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ─────────────────────────────────────────────────────────────────────────────
# objectstorage.tf
#
# Creates the destination Object Storage bucket in the same compartment.
# The function writes FOCUS reports here each day.
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_objectstorage_bucket" "focus_reports" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.destination_bucket_name

  # Standard storage tier – suitable for cost report archives
  storage_tier   = "Standard"
  access_type    = "NoPublicAccess"

  lifecycle {
    ignore_changes = [defined_tags]
  }
}
