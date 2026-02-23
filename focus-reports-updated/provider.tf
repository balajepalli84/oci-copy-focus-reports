# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ─────────────────────────────────────────────────────────────────────────────
# provider.tf
#
# When deployed via OCI Resource Manager, authentication is handled
# automatically by ORM – no user_ocid, fingerprint, or private_key_path needed.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}

provider "oci" {
  region = var.region
}
