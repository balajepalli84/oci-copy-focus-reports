# FOCUS Reports – Daily Export to Object Storage

Terraform stack (deployable via **OCI Resource Manager**) that automates the daily copy of OCI FinOps FOCUS Cost & Usage Reports to your own Object Storage bucket.

Reference: [A-Team blog post](https://www.ateam-oracle.com/automating-the-export-of-oci-finops-open-cost-and-usage-specification-focus-reports-to-object-storage)

---

## Architecture

```
Resource Scheduler  (CRON – daily at 02:00 UTC)
        │
        │  INVOKE_FUNCTION
        ▼
OCI Functions: copy-focus-reports
  ├── reads from: bling/<tenancy-id>/FOCUS Reports/<yyyy>/<mm>/<dd>/
  │   (cross-tenancy via Resource Principal endorsement)
  └── writes to:  <your-namespace>/<destination-bucket>/FOCUS Reports/...
```

---

## Resources Created

| File | Resource |
|---|---|
| `iam.tf` | Dynamic Group + IAM Policy (cross-tenancy read + bucket write + scheduler invoke) |
| `function.tf` | OCIR Repo + `null_resource` (docker build/push) + Functions App + Function |
| `scheduler.tf` | Resource Scheduler schedule (daily CRON) |

---

## Deploying via OCI Resource Manager

1. Zip this entire directory: `zip -r focus-reports-stack.zip .`
2. Go to **OCI Console → Developer Services → Resource Manager → Stacks**
3. Click **Create Stack → My Configuration** and upload the zip
4. The UI form (defined in `schema.yaml`) will prompt for:
   - **Compartment** (dropdown)
   - **VCN** (dropdown, filtered by compartment)
   - **Subnet** (dropdown, filtered by VCN)
   - **OCIR credentials** (username + auth token)
   - **Destination bucket name**
   - **CRON schedule**
5. Click **Apply**

ORM will build the Docker image, push it to OCIR, and wire up all IAM and scheduler resources automatically.

---

## Pre-requisite: Object Storage Bucket

The destination bucket must exist before deploying. Create it in OCI Console or with:

```bash
oci os bucket create --name Cost_Usage_Reports --compartment-id <compartment_ocid>
```

---

## Post-Deployment: Tighten the Scheduler Policy

After the first apply, get the schedule OCID from the Outputs tab in ORM, then update the last statement in `iam.tf`:

```hcl
"Allow any-user to manage functions-family in compartment id <compartment_ocid> where all {request.principal.type = 'resourceschedule', request.principal.id = '<schedule_ocid>'}",
```

---

## Updating the Function

Bump the `version` field in `function/func.yaml` and re-apply the stack. The `null_resource` trigger watches the version field and re-runs the full build → push pipeline.

---

## File Layout

```
.
├── schema.yaml          # ORM UI form definition (dropdowns, labels, sections)
├── provider.tf          # OCI provider – no user credentials needed for ORM
├── variables.tf         # All input variables
├── locals.tf            # region_key, image_path, func.yaml parsing
├── datasources.tf       # Object Storage namespace, region list
├── iam.tf               # Dynamic Group + IAM Policy
├── function.tf          # OCIR repo + build/push + Functions App + Function
├── scheduler.tf         # Resource Scheduler (daily CRON)
├── outputs.tf           # Useful OCIDs + post-deploy checklist
└── function/
    ├── func.py          # Python handler – copies FOCUS reports
    ├── func.yaml        # fn metadata (name, version, memory, timeout)
    └── requirements.txt
```
