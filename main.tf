# Provider configuration is in providers.tf

# Enable required GCP APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "vpcaccess.googleapis.com",
    "iam.googleapis.com",
    "apigee.googleapis.com",
    "servicenetworking.googleapis.com",
    "dns.googleapis.com",
    "storage.googleapis.com"
  ])

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create VPC
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id

  depends_on = [google_project_service.required_apis]
}

# Create subnet with Private Google Access enabled
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  private_ip_google_access = true

  depends_on = [google_project_service.required_apis]
}

# Create Serverless VPC Connector
resource "google_vpc_access_connector" "connector" {
  name          = var.vpc_connector_name
  region        = var.region
  project       = var.project_id
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.vpc_connector_cidr

  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances

  depends_on = [
    google_project_service.required_apis,
    google_compute_subnetwork.subnet
  ]
}

# Service account for Cloud Function
resource "google_service_account" "cloud_function_sa" {
  account_id   = "${var.cloud_function_name}-sa"
  display_name = "Service Account for ${var.cloud_function_name}"
  project      = var.project_id

  depends_on = [google_project_service.required_apis]
}

# Create Apigee service account if not provided
resource "google_service_account" "apigee_sa" {
  count = var.create_apigee_service_account && var.apigee_service_account_email == "" ? 1 : 0

  account_id   = var.apigee_service_account_name
  display_name = "Service Account for Apigee to invoke Cloud Function"
  project      = var.project_id

  depends_on = [google_project_service.required_apis]
}

# Grant necessary permissions to Cloud Function service account
resource "google_project_iam_member" "cloud_function_sa_permissions" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/logging.logWriter"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"

  depends_on = [google_service_account.cloud_function_sa]
}

# Create Cloud Function (2nd gen) with internal ingress
resource "google_cloudfunctions2_function" "function" {
  name        = var.cloud_function_name
  location    = var.region
  description = "Private Cloud Function accessible only via VPC"
  project     = var.project_id

  build_config {
    runtime     = var.cloud_function_runtime
    entry_point = var.cloud_function_entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = var.cloud_function_source_path != "" ? google_storage_bucket_object.function_source_custom[0].name : google_storage_bucket_object.function_source_generated[0].name
      }
    }
  }

  service_config {
    min_instance_count    = var.cloud_function_min_instances
    max_instance_count    = var.cloud_function_max_instances
    available_memory      = var.cloud_function_memory
    timeout_seconds       = var.cloud_function_timeout
    service_account_email = google_service_account.cloud_function_sa.email
    ingress_settings      = "ALLOW_INTERNAL_ONLY"
    vpc_connector         = google_vpc_access_connector.connector.name
    vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"

    environment_variables = var.cloud_function_env_vars
  }

  depends_on = [
    google_project_service.required_apis,
    google_vpc_access_connector.connector,
    google_storage_bucket_object.function_source_custom,
    google_storage_bucket_object.function_source_generated
  ]
}

# Determine which Apigee service account to use
locals {
  apigee_service_account_email = var.apigee_service_account_email != "" ? var.apigee_service_account_email : (
    var.create_apigee_service_account && length(google_service_account.apigee_sa) > 0 ? google_service_account.apigee_sa[0].email : ""
  )
}

# IAM binding: Only Apigee service account can invoke the function
resource "google_cloudfunctions2_function_iam_member" "apigee_invoker" {
  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${local.apigee_service_account_email}"

  depends_on = [
    google_cloudfunctions2_function.function,
    google_service_account.apigee_sa
  ]
}

# Storage bucket for Cloud Function source code
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-${var.cloud_function_name}-source"
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  depends_on = [google_project_service.required_apis]
}

# Create placeholder function source files if not provided
resource "local_file" "function_main" {
  count    = var.cloud_function_source_path == "" ? 1 : 0
  filename = "${path.module}/function-source/main.py"
  content = <<-EOF
import functions_framework
import json

@functions_framework.http
def hello_world(request):
    """HTTP Cloud Function that returns a greeting."""
    request_json = request.get_json(silent=True)
    request_args = request.args

    if request_json and 'name' in request_json:
        name = request_json['name']
    elif request_args and 'name' in request_args:
        name = request_args['name']
    else:
        name = 'World'
    
    return json.dumps({
        'message': f'Hello {name}!',
        'status': 'success'
    }), 200, {'Content-Type': 'application/json'}
EOF
}

resource "local_file" "function_requirements" {
  count    = var.cloud_function_source_path == "" ? 1 : 0
  filename = "${path.module}/function-source/requirements.txt"
  content  = "functions-framework==3.*\n"
}

# Archive the function source code
data "archive_file" "function_source" {
  count = var.cloud_function_source_path == "" ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/function-source"
  output_path = "${path.module}/function-source.zip"

  depends_on = [
    local_file.function_main,
    local_file.function_requirements
  ]
}

# Upload function source to GCS (when using custom source path)
resource "google_storage_bucket_object" "function_source_custom" {
  count = var.cloud_function_source_path != "" ? 1 : 0

  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = var.cloud_function_source_path

  depends_on = [google_storage_bucket.function_source]
}

# Upload function source to GCS (when using generated placeholder)
resource "google_storage_bucket_object" "function_source_generated" {
  count = var.cloud_function_source_path == "" ? 1 : 0

  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source[0].output_path

  depends_on = [
    google_storage_bucket.function_source,
    data.archive_file.function_source
  ]
}

# Private DNS Zone for internal service discovery
resource "google_dns_managed_zone" "internal_zone" {
  count = var.enable_private_dns ? 1 : 0

  name        = var.private_dns_zone_name
  dns_name    = var.private_dns_domain
  description = "Private DNS zone for internal services"
  project     = var.project_id

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }

  depends_on = [
    google_project_service.required_apis,
    google_compute_network.vpc
  ]
}

# DNS record for Cloud Function (if private DNS is enabled)
resource "google_dns_record_set" "function_dns" {
  count = var.enable_private_dns ? 1 : 0

  managed_zone = google_dns_managed_zone.internal_zone[0].name
  name         = "${var.cloud_function_dns_name}.${var.private_dns_domain}"
  type         = "CNAME"
  ttl          = 300
  # CNAME records need hostname only (without https://)
  rrdatas      = [replace(google_cloudfunctions2_function.function.service_config[0].uri, "https://", "")]

  project = var.project_id

  depends_on = [
    google_dns_managed_zone.internal_zone,
    google_cloudfunctions2_function.function
  ]
}

# Firewall rule to allow internal VPC traffic (for Apigee to Cloud Function communication)
resource "google_compute_firewall" "allow_internal_traffic" {
  name    = "${var.vpc_name}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }

  source_ranges = [var.subnet_cidr, var.vpc_connector_cidr]
  target_tags   = ["apigee", "cloud-function"]

  description = "Allow internal VPC traffic for Apigee and Cloud Function communication"

  depends_on = [google_compute_network.vpc]
}

# Firewall rule to allow VPN traffic to Apigee (if VPN is configured)
resource "google_compute_firewall" "allow_vpn_to_apigee" {
  count = var.enable_vpn_access ? 1 : 0

  name    = "${var.vpc_name}-allow-vpn-to-apigee"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443", "80"]
  }

  source_ranges = var.vpn_source_ranges
  target_tags   = ["apigee"]

  description = "Allow VPN traffic to Apigee (internal access only)"

  depends_on = [google_compute_network.vpc]
}

# Deny all external internet traffic (explicit deny for security)
resource "google_compute_firewall" "deny_external_traffic" {
  name      = "${var.vpc_name}-deny-external"
  network   = google_compute_network.vpc.name
  project   = var.project_id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["apigee", "cloud-function"]

  description = "Explicitly deny all external internet traffic to Apigee and Cloud Function"

  depends_on = [google_compute_network.vpc]
}

# Create Apigee Instance with Internal Peering (Private)
# Note: VPC peering is configured via ip_range which creates internal peering
resource "google_apigee_instance" "apigee_instance" {
  count = var.create_apigee_instance && var.apigee_org_id != "" ? 1 : 0

  name                     = var.apigee_instance_name
  location                 = var.region
  org_id                   = var.apigee_org_id
  description              = "Private Apigee instance with internal peering"
  disk_encryption_key_name  = var.apigee_disk_encryption_key_name != "" ? var.apigee_disk_encryption_key_name : null
  consumer_accept_list      = var.apigee_consumer_accept_list

  # Internal peering configuration (private, not external)
  # The ip_range creates the peering CIDR range for internal VPC peering
  ip_range = var.apigee_peering_cidr_range

  depends_on = [
    google_project_service.required_apis,
    google_compute_network.vpc
  ]
}

# Note: VPC network attachment for Apigee instance is done via gcloud or UI after instance creation
# The instance needs to be attached to the VPC network using:
# gcloud apigee instances attach INSTANCE_NAME \
#   --environment=ENV_NAME \
#   --network=projects/PROJECT_ID/global/networks/VPC_NAME
#
# Or use the Apigee UI to attach the instance to the VPC network
# This creates the INTERNAL peering connection (private, not external)
#
# The ip_range specified above is used as the peering CIDR range for internal VPC peering

# Create Apigee Environment (if org_id and env_name are provided)
resource "google_apigee_environment" "apigee_env" {
  count = var.create_apigee_instance && var.apigee_org_id != "" && var.apigee_env_name != "" ? 1 : 0

  org_id       = var.apigee_org_id
  name         = var.apigee_env_name
  description  = "Private Apigee environment for internal backend"
  display_name = var.apigee_env_display_name != "" ? var.apigee_env_display_name : var.apigee_env_name

  # Optional: Add API proxy type restrictions if needed
  # api_proxy_type = "PROGRAMMABLE"

  depends_on = [
    google_project_service.required_apis,
    google_apigee_instance.apigee_instance
  ]
}

# Attach Environment to Instance
resource "google_apigee_environment_iam_binding" "apigee_env_instance_binding" {
  count = var.create_apigee_instance && var.apigee_org_id != "" && var.apigee_env_name != "" && length(google_apigee_instance.apigee_instance) > 0 ? 1 : 0

  org_id  = var.apigee_org_id
  env_id  = google_apigee_environment.apigee_env[0].name
  role    = "roles/apigee.environmentAdmin"

  members = [
    "serviceAccount:${local.apigee_service_account_email}"
  ]

  depends_on = [
    google_apigee_environment.apigee_env,
    google_apigee_instance.apigee_instance
  ]
}

