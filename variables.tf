variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region (e.g., asia-south1)"
  type        = string
  default     = "asia-south1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "private-backend-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "private-backend-subnet"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector"
  type        = string
  default     = "private-backend-connector"
}

variable "vpc_connector_cidr" {
  description = "CIDR block for the VPC connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "vpc_connector_min_instances" {
  description = "Minimum instances for VPC connector"
  type        = number
  default     = 2
}

variable "vpc_connector_max_instances" {
  description = "Maximum instances for VPC connector"
  type        = number
  default     = 3
}

variable "cloud_function_name" {
  description = "Name of the Cloud Function"
  type        = string
  default     = "private-backend-function"
}

variable "cloud_function_runtime" {
  description = "Runtime for Cloud Function (e.g., python311, nodejs18)"
  type        = string
  default     = "python311"
}

variable "cloud_function_entry_point" {
  description = "Entry point function name"
  type        = string
  default     = "hello_world"
}

variable "cloud_function_memory" {
  description = "Memory allocation for Cloud Function (e.g., 256Mi, 512Mi)"
  type        = string
  default     = "256Mi"
}

variable "cloud_function_timeout" {
  description = "Timeout in seconds for Cloud Function"
  type        = number
  default     = 60
}

variable "cloud_function_min_instances" {
  description = "Minimum instances for Cloud Function"
  type        = number
  default     = 0
}

variable "cloud_function_max_instances" {
  description = "Maximum instances for Cloud Function"
  type        = number
  default     = 10
}

variable "cloud_function_env_vars" {
  description = "Environment variables for Cloud Function"
  type        = map(string)
  default     = {}
}

variable "cloud_function_source_path" {
  description = "Path to Cloud Function source code zip file (leave empty to use placeholder)"
  type        = string
  default     = ""
}

variable "apigee_service_account_email" {
  description = "Email of the Apigee service account that can invoke the Cloud Function. If not provided, a new service account will be created."
  type        = string
  default     = ""
}

variable "create_apigee_service_account" {
  description = "Whether to create an Apigee service account. If true and apigee_service_account_email is empty, a new SA will be created."
  type        = bool
  default     = true
}

variable "apigee_service_account_name" {
  description = "Name for the Apigee service account (only used if creating a new one)"
  type        = string
  default     = "apigee-invoker-sa"
}

variable "enable_private_dns" {
  description = "Enable private DNS zone for internal service discovery"
  type        = bool
  default     = true
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  type        = string
  default     = "internal-zone"
}

variable "private_dns_domain" {
  description = "DNS domain for private zone (e.g., internal.mystore.)"
  type        = string
  default     = "internal.mystore."
}

variable "cloud_function_dns_name" {
  description = "DNS name for Cloud Function (e.g., api)"
  type        = string
  default     = "api"
}

# Apigee Instance Configuration
variable "create_apigee_instance" {
  description = "Whether to create an Apigee instance with internal peering"
  type        = bool
  default     = false
}

variable "apigee_org_id" {
  description = "Apigee Organization ID (required if create_apigee_instance is true)"
  type        = string
  default     = ""
}

variable "apigee_instance_name" {
  description = "Name of the Apigee instance"
  type        = string
  default     = "apigee-instance"
}

variable "apigee_peering_cidr_range" {
  description = "CIDR range for Apigee instance peering (e.g., 10.1.0.0/22). Must not overlap with subnet or connector CIDRs."
  type        = string
  default     = "10.1.0.0/22"
}

variable "apigee_env_name" {
  description = "Apigee Environment name (optional, will be created if provided)"
  type        = string
  default     = ""
}

variable "apigee_env_display_name" {
  description = "Display name for Apigee environment"
  type        = string
  default     = ""
}

variable "apigee_disk_encryption_key_name" {
  description = "Customer-managed encryption key name for Apigee instance (optional)"
  type        = string
  default     = ""
}

variable "apigee_consumer_accept_list" {
  description = "List of consumer projects that are allowed to access the Apigee instance (for private access)"
  type        = list(string)
  default     = []
}

variable "enable_vpn_access" {
  description = "Enable VPN access to Apigee (for internal access via VPN)"
  type        = bool
  default     = true
}

variable "vpn_source_ranges" {
  description = "CIDR ranges for VPN access (e.g., ['10.0.1.0/24']). Only used if enable_vpn_access is true."
  type        = list(string)
  default     = []
}

