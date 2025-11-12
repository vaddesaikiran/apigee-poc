output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = google_compute_subnetwork.subnet.id
}

output "vpc_connector_name" {
  description = "Name of the VPC connector"
  value       = google_vpc_access_connector.connector.name
}

output "vpc_connector_id" {
  description = "ID of the VPC connector"
  value       = google_vpc_access_connector.connector.id
}

output "cloud_function_name" {
  description = "Name of the Cloud Function"
  value       = google_cloudfunctions2_function.function.name
}

output "cloud_function_url" {
  description = "Internal URL of the Cloud Function (for Apigee to call)"
  value       = google_cloudfunctions2_function.function.service_config[0].uri
}

output "cloud_function_hostname" {
  description = "Hostname of the Cloud Function"
  value       = replace(google_cloudfunctions2_function.function.service_config[0].uri, "https://", "")
}

output "cloud_function_service_account" {
  description = "Service account email used by Cloud Function"
  value       = google_service_account.cloud_function_sa.email
}

output "apigee_service_account_email" {
  description = "Service account email used by Apigee to invoke the function (created or provided)"
  value       = local.apigee_service_account_email
}

output "apigee_service_account_created" {
  description = "Whether the Apigee service account was created by Terraform"
  value       = var.create_apigee_service_account && var.apigee_service_account_email == ""
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone (if enabled)"
  value       = var.enable_private_dns ? google_dns_managed_zone.internal_zone[0].name : null
}

output "cloud_function_dns_name" {
  description = "DNS name for Cloud Function (if private DNS is enabled)"
  value       = var.enable_private_dns ? "${var.cloud_function_dns_name}.${var.private_dns_domain}" : null
}

output "function_invoke_url" {
  description = "Full URL to invoke the function (internal only)"
  value       = "${google_cloudfunctions2_function.function.service_config[0].uri}/${var.cloud_function_entry_point}"
}

output "vpc_network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_self_link" {
  description = "Self link of the subnet"
  value       = google_compute_subnetwork.subnet.self_link
}

output "apigee_instance_name" {
  description = "Name of the Apigee instance (if created)"
  value       = var.create_apigee_instance && var.apigee_org_id != "" ? google_apigee_instance.apigee_instance[0].name : null
}

output "apigee_instance_id" {
  description = "ID of the Apigee instance (if created)"
  value       = var.create_apigee_instance && var.apigee_org_id != "" ? google_apigee_instance.apigee_instance[0].id : null
}

output "apigee_instance_host" {
  description = "Hostname of the Apigee instance (if created)"
  value       = var.create_apigee_instance && var.apigee_org_id != "" ? google_apigee_instance.apigee_instance[0].host : null
}

output "apigee_environment_name" {
  description = "Name of the Apigee environment (if created)"
  value       = var.create_apigee_instance && var.apigee_org_id != "" && var.apigee_env_name != "" ? google_apigee_environment.apigee_env[0].name : null
}

