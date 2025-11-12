# GCP Project Configuration
project_id = "gcppoc-477305"
region     = "asia-south1"

# VPC Configuration
vpc_name   = "private-backend-vpc"
subnet_name = "private-backend-subnet"
subnet_cidr = "10.0.0.0/24"

# VPC Connector Configuration
vpc_connector_name        = "private-backend-connector"
vpc_connector_cidr        = "10.8.0.0/28"
vpc_connector_min_instances = 2
vpc_connector_max_instances = 3

# Cloud Function Configuration
cloud_function_name        = "private-backend-function"
cloud_function_runtime     = "python311"
cloud_function_entry_point = "hello_world"
cloud_function_memory      = "256Mi"
cloud_function_timeout     = 60
cloud_function_min_instances = 0
cloud_function_max_instances = 10

# Cloud Function Source (leave empty to use placeholder)
# cloud_function_source_path = "/path/to/your/function-source.zip"

# Environment variables for Cloud Function
cloud_function_env_vars = {
  # ENV_VAR_1 = "value1"
  # ENV_VAR_2 = "value2"
}

# Apigee Configuration
# Option 1: Let Terraform create a new service account (RECOMMENDED)
create_apigee_service_account = true
apigee_service_account_name    = "apigee-invoker-sa"
# apigee_service_account_email = ""  # Leave empty to create new SA

# Option 2: Use an existing service account (if you prefer)
# Uncomment and use one of your existing service accounts:
# apigee_service_account_email = "gcp-poc-gen2-functions@gcppoc-477305.iam.gserviceaccount.com"
# create_apigee_service_account = false

# Private DNS Configuration
# Disabled - Using direct hostnames instead (no domain needed)
enable_private_dns     = false
# private_dns_zone_name  = "internal-zone"
# private_dns_domain     = "internal.mystore."
# cloud_function_dns_name = "api"

# VPN Configuration (for accessing Apigee)
enable_vpn_access = true
# Update with your VPN CIDR ranges when VPN is configured
# Example: vpn_source_ranges = ["10.0.1.0/24", "10.0.2.0/24"]
vpn_source_ranges = []

# Apigee Instance Configuration (with Internal Peering)
# IMPORTANT: You must create Apigee organization FIRST to get the org_id
# Run: gcloud apigee organizations provision --project-id=gcppoc-477305 --analytics-region=asia-south1 --runtime-type=CLOUD
# Then: gcloud apigee organizations list (to get the org_id)
# Then update apigee_org_id below with the actual ID
create_apigee_instance = true
apigee_org_id = "gcppoc-477305"  # ✅ Apigee organization created
apigee_instance_name = "apigee-instance"
apigee_peering_cidr_range = "10.1.0.0/22"  # Must not overlap with subnet (10.0.0.0/24) or connector (10.8.0.0/28)
apigee_env_name = "prod"  # Create environment
apigee_env_display_name = "Production Environment"

