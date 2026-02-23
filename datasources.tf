# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ─────────────────────────────────────────────────────────────────────────────
# datasources.tf
# ─────────────────────────────────────────────────────────────────────────────

# Object Storage namespace – used to build the OCIR image path
data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.tenancy_ocid
}

# All OCI regions – used to map var.region → short region key (e.g. iad, phx)
data "oci_identity_regions" "all" {}
