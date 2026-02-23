# Copyright (c) 2025, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

# ─────────────────────────────────────────────────────────────────────────────
# variables.tf
#
# All variables here correspond 1-to-1 with entries in schema.yaml.
# ORM populates tenancy_ocid automatically – it does NOT appear in schema.yaml
# but must exist in variables.tf so Terraform can reference it.
# ─────────────────────────────────────────────────────────────────────────────

# ORM injects this automatically; not shown in the UI form
variable "tenancy_ocid" {}

variable "region" {
  description = "OCI region identifier (e.g. us-ashburn-1)"
  type        = string
}

# ── Network ──────────────────────────────────────────────────────────────────
variable "compartment_ocid" {
  description = "Compartment where all resources are created"
  type        = string
}

variable "vcn_ocid" {
  description = "VCN OCID (UI dropdown)"
  type        = string
}

variable "subnet_ocid" {
  description = "Subnet OCID for the Functions Application (UI dropdown)"
  type        = string
}

# ── OCIR ─────────────────────────────────────────────────────────────────────
variable "ocir_username" {
  description = "OCIR login username (e.g. oracleidentitycloudservice/<email>)"
  type        = string
}

variable "ocir_password" {
  description = "OCI Auth Token for OCIR"
  type        = string
  sensitive   = true
}

variable "repository_name" {
  description = "OCIR repository name"
  type        = string
  default     = "focus-reports-repo"
}

# ── Functions Application & Function names ────────────────────────────────────
variable "app_display_name" {
  description = "Display name for the OCI Functions Application"
  type        = string
  default     = "focus-reports-app"
}

variable "function_display_name" {
  description = "Display name for the OCI Function"
  type        = string
  default     = "copy-focus-reports"
}

# ── Object Storage ────────────────────────────────────────────────────────────
variable "destination_bucket_name" {
  description = "Name of the Object Storage bucket to create for FOCUS reports"
  type        = string
  default     = "Cost_Usage_Reports"
}

# ── Scheduler ─────────────────────────────────────────────────────────────────
variable "schedule_display_name" {
  description = "Display name for the Resource Scheduler schedule"
  type        = string
  default     = "focus-reports-daily-schedule"
}

variable "schedule_cron_expression" {
  description = "CRON expression for daily invocation (UTC)"
  type        = string
  default     = "0 2 * * *"
}

# ── IAM ───────────────────────────────────────────────────────────────────────
variable "policy_name" {
  description = "IAM policy name"
  type        = string
  default     = "policy-focus-reports-automation"
}

# ── Function tuning ───────────────────────────────────────────────────────────
variable "function_memory_in_mbs" {
  description = "Memory allocated to the function (MB)"
  type        = number
  default     = 512
}

variable "function_timeout_in_seconds" {
  description = "Function execution timeout (seconds)"
  type        = number
  default     = 300
}

variable "function_parameters_json_string" {
  description = "Optional JSON string of extra function config key-value pairs"
  type        = string
  default     = ""
}

# ── Internal – not shown in UI ────────────────────────────────────────────────
variable "function_working_dir" {
  description = "Path to the directory containing func.py, func.yaml, requirements.txt"
  type        = string
  default     = "./function"
}
