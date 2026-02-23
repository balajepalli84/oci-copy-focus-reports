# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "destination_bucket_name" {
  description = "Name of the Object Storage bucket created for FOCUS reports"
  value       = oci_objectstorage_bucket.focus_reports.name
}

output "function_ocid" {
  description = "OCID of the deployed function – embedded in IAM policy statements as the Resource Principal identity"
  value       = oci_functions_function.this.id
}

output "function_id" {
  description = "OCID of the deployed copy-focus-reports function"
  value       = oci_functions_function.this.id
}

output "function_invoke_endpoint" {
  description = "HTTPS endpoint to invoke the function directly for testing"
  value       = oci_functions_function.this.invoke_endpoint
}

output "functions_application_id" {
  description = "OCID of the Functions Application"
  value       = oci_functions_application.this.id
}

output "schedule_ocid" {
  description = "OCID of the Resource Scheduler schedule (created via OCI CLI)"
  value       = oci_resource_scheduler_schedule.this.id
}

output "image_path" {
  description = "Full OCIR image path that was built and pushed"
  value       = local.image_path
}

output "next_steps" {
  description = "Post-deployment checklist"
  value = <<-EOT
    ─────────────────────────────────────────────────────────────────────
    FOCUS Reports Automation – Post-Deployment Checklist
    ─────────────────────────────────────────────────────────────────────

    1. BUCKET CREATED:
       Terraform created '${var.destination_bucket_name}' automatically.

    2. TIGHTEN SCHEDULER POLICY (recommended for production):
       Get the schedule OCID from the 'schedule_ocid' output above, then
       update the last policy statement in iam.tf to scope it further:

         Allow any-user to manage functions-family in compartment id ${var.compartment_ocid}
           where all {
             request.principal.type = 'resourceschedule',
             request.principal.id   = '<schedule_ocid>'
           }

    3. TEST MANUALLY (OCI Cloud Shell):
       echo '{}' | fn invoke ${local.function_name}-function-application ${local.function_name}-function

    4. SCHEDULE: runs at CRON '${var.schedule_cron_expression}' UTC
    ─────────────────────────────────────────────────────────────────────
  EOT
}
