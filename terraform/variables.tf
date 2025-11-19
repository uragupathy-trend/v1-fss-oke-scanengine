# Simplified Variables for OKE File Security Scanning Engine
# Optimized for minimal OKE cluster deployment using existing OCI infrastructure

# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================

variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the public key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region"
  type        = string
  default     = "us-ashburn-1"
}

# ==============================================================================
# EXISTING INFRASTRUCTURE
# ==============================================================================

variable "compartment_ocid" {
  description = "The OCID of the existing compartment where OKE cluster will be created"
  type        = string
}

variable "vcn_ocid" {
  description = "The OCID of the existing VCN"
  type        = string
}

variable "api_endpoint_subnet_ocid" {
  description = "The OCID of the existing subnet for OKE API endpoint"
  type        = string
}

variable "worker_node_subnet_ocid" {
  description = "The OCID of the existing subnet for worker nodes"
  type        = string
}

variable "load_balancer_subnet_ocid" {
  description = "The OCID of the existing subnet for load balancers"
  type        = string
}

# ==============================================================================
# CLUSTER CONFIGURATION
# ==============================================================================

variable "cluster_name" {
  description = "Name of the OKE cluster"
  type        = string
  default     = "fss-oke-scanengine"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "v1.34.1"
}

variable "cluster_endpoint_visibility" {
  description = "Whether the cluster endpoint should be public or private"
  type        = string
  default     = "Public"
  validation {
    condition     = contains(["Public", "Private"], var.cluster_endpoint_visibility)
    error_message = "Cluster endpoint visibility must be either 'Public' or 'Private'."
  }
}

variable "cluster_pods_cidr" {
  description = "CIDR block for Kubernetes pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "cluster_services_cidr" {
  description = "CIDR block for Kubernetes services"
  type        = string
  default     = "10.96.0.0/16"
}

variable "environment" {
  description = "Environment name for resource tagging"
  type        = string
  default     = "production"
}

# ==============================================================================
# NODE POOL CONFIGURATION
# ==============================================================================

variable "node_pool_size" {
  description = "Number of worker nodes in the node pool"
  type        = number
  default     = 3
  validation {
    condition     = var.node_pool_size >= 1 && var.node_pool_size <= 50
    error_message = "Node pool size must be between 1 and 50."
  }
}

variable "node_shape" {
  description = "Shape of the worker nodes"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "node_shape_ocpus" {
  description = "Number of OCPUs for flexible node shapes"
  type        = number
  default     = 2
  validation {
    condition     = var.node_shape_ocpus >= 1 && var.node_shape_ocpus <= 64
    error_message = "OCPUs must be between 1 and 64."
  }
}

variable "node_memory_gb" {
  description = "Amount of memory in GBs for flexible node shapes"
  type        = number
  default     = 16
  validation {
    condition     = var.node_memory_gb >= 1 && var.node_memory_gb <= 1024
    error_message = "Memory must be between 1 and 1024 GBs."
  }
}

variable "node_boot_volume_size_gb" {
  description = "Size of the boot volume for worker nodes in GBs"
  type        = number
  default     = 100
  validation {
    condition     = var.node_boot_volume_size_gb >= 50 && var.node_boot_volume_size_gb <= 32768
    error_message = "Boot volume size must be between 50 and 32768 GBs."
  }
}

variable "node_image_ocid" {
  description = "OCID of the image to use for worker nodes (leave empty to use latest Oracle Linux)"
  type        = string
  default     = ""
}

variable "ssh_public_key" {
  description = "SSH public key for accessing worker nodes"
  type        = string
  default     = ""
}

# ==============================================================================
# AVAILABILITY DOMAINS
# ==============================================================================

variable "availability_domains" {
  description = "List of availability domains for node placement"
  type        = list(string)
  default     = []
}

# ==============================================================================
# AUTOSCALING CONFIGURATION
# ==============================================================================

variable "enable_autoscaling" {
  description = "Whether to enable cluster autoscaling"
  type        = bool
  default     = false
}

variable "min_node_count" {
  description = "Minimum number of nodes when autoscaling is enabled"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes when autoscaling is enabled"
  type        = number
  default     = 10
}
