# Simplified Data Sources for OKE Cluster
# Essential data sources for OKE cluster deployment

# ==============================================================================
# AVAILABILITY DOMAINS
# ==============================================================================

data "oci_identity_availability_domains" "cluster_ads" {
  compartment_id = var.tenancy_ocid
}

# ==============================================================================
# COMPUTE IMAGES
# ==============================================================================

data "oci_core_images" "oracle_linux_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"

  filter {
    name   = "display_name"
    values = ["^.*Oracle-Linux-8.*-OKE-.*$"]
    regex  = true
  }
}

# ==============================================================================
# KUBERNETES PROVIDER CONFIGURATION
# ==============================================================================

data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
  cluster_id    = oci_containerengine_cluster.oke_cluster.id
  token_version = "2.0.0"
  expiration    = 2592000
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  # Use provided availability domains or default to all available
  availability_domains = length(var.availability_domains) > 0 ? var.availability_domains : [
    for ad in data.oci_identity_availability_domains.cluster_ads.availability_domains : ad.name
  ]

  # Use provided node image or latest Oracle Linux OKE image (with fallback)
  node_image_id = var.node_image_ocid != "" ? var.node_image_ocid : (
    length(data.oci_core_images.oracle_linux_images.images) > 0 ? 
    data.oci_core_images.oracle_linux_images.images[0].id : 
    "ocid1.image.oc1.ap-sydney-1.aaaaaaaaylztjh7mszpzm4mjgjk4rdnfkmvuprvkrxu7o2rnsnqvnfajggna" # Oracle Linux 8 OKE fallback
  )

  # Determine if the node shape is flexible
  is_flexible_shape = contains(["VM.Standard.E3.Flex", "VM.Standard.E4.Flex", "VM.Standard.E5.Flex"], var.node_shape)

  # Common tags for all resources
  common_tags = {
    Environment = var.environment
    Project     = "FSS-OKE-ScanEngine"
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}
