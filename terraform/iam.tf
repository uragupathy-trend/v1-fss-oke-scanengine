# IAM Configuration for OCI OKE File Security Scanning Engine
# Creates dynamic groups and policies required for OKE cluster operations

# ==============================================================================
# DYNAMIC GROUPS
# ==============================================================================

# Dynamic group for OKE cluster service
resource "oci_identity_dynamic_group" "oke_cluster_service_group" {
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-cluster-service-group"
  description    = "Dynamic group for OKE cluster service operations"
  
  matching_rule = "ALL {resource.type = 'cluster', resource.compartment.id = '${var.compartment_ocid}'}"
  
  freeform_tags = local.common_tags
}

# Dynamic group for OKE worker nodes
resource "oci_identity_dynamic_group" "oke_worker_nodes_group" {
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-worker-nodes-group"
  description    = "Dynamic group for OKE worker node instances"
  
  matching_rule = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
  
  freeform_tags = local.common_tags
}

# ==============================================================================
# IAM POLICIES
# ==============================================================================

# Policy for OKE cluster service operations
resource "oci_identity_policy" "oke_cluster_service_policy" {
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-cluster-service-policy"
  description    = "Policy for OKE cluster service operations"
  
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to manage cluster-node-pools in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to manage vnics in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to use subnets in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to read virtual-network-family in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to use vnics in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to inspect compartments in compartment id ${var.compartment_ocid}"
  ]
  
  freeform_tags = local.common_tags
}

# Policy for OKE worker nodes
resource "oci_identity_policy" "oke_worker_nodes_policy" {
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-worker-nodes-policy"
  description    = "Policy for OKE worker node operations"
  
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_group.name} to use volumes in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_worker_nodes_group.name} to manage volume-attachments in compartment id ${var.compartment_ocid}"
  ]
  
  freeform_tags = local.common_tags
}

# Additional policies for cluster autoscaling operations
resource "oci_identity_policy" "cluster_autoscaling_policy" {
  count = var.enable_autoscaling ? 1 : 0
  
  compartment_id = var.tenancy_ocid
  name           = "${var.cluster_name}-autoscaling-policy"
  description    = "Policy for cluster autoscaling operations"
  
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to manage instance-family in compartment id ${var.compartment_ocid}",
    "allow dynamic-group ${oci_identity_dynamic_group.oke_cluster_service_group.name} to use images in compartment id ${var.compartment_ocid}"
  ]
  
  freeform_tags = local.common_tags
}
