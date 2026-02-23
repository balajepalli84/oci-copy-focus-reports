# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_resource_scheduler_schedule" "this" {
  action             = "START_RESOURCE"
  compartment_id     = var.compartment_ocid
  display_name       = var.schedule_display_name
  description        = "Daily FOCUS reports export to Object Storage"
  recurrence_type    = "CRON"
  recurrence_details = "0 2 * * *"

  resources {
    id = oci_functions_function.this.id
  }

  depends_on = [
    oci_functions_function.this,
  ]
}
