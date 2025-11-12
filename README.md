# Private GCP Backend with Cloud Function and Apigee

This Terraform configuration creates a fully private backend infrastructure on GCP with:
- VPC with Private Google Access enabled
- Serverless VPC Connector
- Cloud Function (2nd gen) with internal-only ingress
- Private DNS zone (optional)
- IAM bindings for Apigee service account

## Architecture

```
Internet/VPN
    ↓
Apigee (Private/Internal)
    ↓
Cloud Function (Internal Only, via VPC Connector)
    ↓
VPC Resources (Firestore, GCS, etc.)
```

## Prerequisites

1. **GCP Project** with billing enabled
2. **Terraform** >= 1.0 installed
3. **Google Cloud SDK** installed and authenticated
4. **Apigee Organization** (if using Apigee - requires separate setup)
5. **Apigee Service Account** email address

## Setup Instructions

### 1. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:
- `project_id`: Your GCP project ID
- `apigee_service_account_email`: Your Apigee service account email
- Other variables as needed

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

## Important Notes

### Cloud Function Source Code

If you don't provide `cloud_function_source_path`, Terraform will create a placeholder Python function. For production, you should:

1. Create your function source code
2. Package it as a zip file
3. Set `cloud_function_source_path` in `terraform.tfvars`

Example function structure:
```
function-source/
├── main.py
└── requirements.txt
```

### Apigee Configuration

Apigee requires separate setup:
1. Create an Apigee organization (if not exists)
2. Create an Apigee environment
3. Use the provided template files (`apigee-proxy-template.xml` and `apigee-target-template.xml`) to create your API proxy

The Cloud Function URL will be available in Terraform outputs. Use this URL in your Apigee target endpoint configuration.

### Accessing the Services

**Cloud Function:**
- **Internal only** - Not accessible from the internet
- Only accessible via VPC or through Apigee service account
- Use the hostname from Terraform outputs

**Apigee:**
- Configure Apigee to be accessible via VPN (as mentioned in requirements)
- Apigee will call the Cloud Function using its service account
- The function is configured to only accept invocations from the specified Apigee service account

### Private DNS

If `enable_private_dns` is set to `true`, the Cloud Function will be accessible via:
- `api.internal.mystore` (or your configured domain)

This requires DNS resolution from within the VPC.

## Outputs

After applying, Terraform will output:
- VPC name and ID
- Subnet name and ID
- VPC connector name and ID
- Cloud Function URL and hostname
- Private DNS information (if enabled)

Use these outputs to configure your Apigee proxy.

## Security

- ✅ Cloud Function has **internal-only ingress** (no public access)
- ✅ Only Apigee service account can invoke the function
- ✅ VPC connector enables private access to GCP services (Firestore, GCS)
- ✅ Private Google Access enabled on subnet
- ✅ All communication is private within VPC

## Troubleshooting

### API Not Enabled
If you get errors about APIs not being enabled, wait a few minutes after the first apply and run `terraform apply` again. API enablement can take time.

### VPC Connector Issues
Ensure the VPC connector CIDR doesn't overlap with your subnet CIDR or other network ranges.

### Cloud Function Not Invokable
Verify:
1. Apigee service account email is correct
2. IAM binding was created successfully
3. Function is deployed and active

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning:** This will delete all resources created by this configuration.

## Additional Resources

- [Cloud Functions 2nd Gen Documentation](https://cloud.google.com/functions/docs/2nd-gen/overview)
- [Serverless VPC Access](https://cloud.google.com/vpc/docs/configure-serverless-vpc-access)
- [Apigee Documentation](https://cloud.google.com/apigee/docs)

