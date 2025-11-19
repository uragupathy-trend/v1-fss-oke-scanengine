# Optimized OKE Cluster Configuration for File Security Scanning
# Simplified and minimal configuration for OKE cluster deployment

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  # Cluster endpoint configuration
  cluster_endpoint_config = {
    is_public_ip_enabled = var.cluster_endpoint_visibility == "Public"
    subnet_id            = var.api_endpoint_subnet_ocid
    nsg_ids              = []
  }
}

# ==============================================================================
# OKE CLUSTER
# ==============================================================================

resource "oci_containerengine_cluster" "oke_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.vcn_ocid

  endpoint_config {
    is_public_ip_enabled = local.cluster_endpoint_config.is_public_ip_enabled
    subnet_id            = local.cluster_endpoint_config.subnet_id
  }

  options {
    service_lb_subnet_ids = [var.load_balancer_subnet_ocid]

    kubernetes_network_config {
      pods_cidr     = var.cluster_pods_cidr
      services_cidr = var.cluster_services_cidr
    }

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

  }

  freeform_tags = local.common_tags

  lifecycle {
    ignore_changes = [kubernetes_version]
  }
}

# ==============================================================================
# NODE POOL
# ==============================================================================

resource "oci_containerengine_node_pool" "worker_nodes" {
  cluster_id         = oci_containerengine_cluster.oke_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "${var.cluster_name}-workers"
  node_shape         = var.node_shape

  dynamic "node_shape_config" {
    for_each = local.is_flexible_shape ? [1] : []
    content {
      ocpus         = var.node_shape_ocpus
      memory_in_gbs = var.node_memory_gb
    }
  }

  node_source_details {
    image_id                = local.node_image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = var.node_boot_volume_size_gb
  }

  node_config_details {
    dynamic "placement_configs" {
      for_each = local.availability_domains
      content {
        availability_domain = placement_configs.value
        subnet_id           = var.worker_node_subnet_ocid
        fault_domains       = ["FAULT-DOMAIN-1"]
      }
    }

    size                                = var.node_pool_size
    is_pv_encryption_in_transit_enabled = true
    freeform_tags                       = local.common_tags
  }

  initial_node_labels {
    key   = "node-pool"
    value = "worker-nodes"
  }

  node_pool_cycling_details {
    is_node_cycling_enabled = true
    maximum_surge           = "1"
    maximum_unavailable     = "0"
  }

  freeform_tags = local.common_tags

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      node_source_details[0].image_id
    ]
  }

  depends_on = [oci_containerengine_cluster.oke_cluster]
}

# ==============================================================================
# CLUSTER AUTOSCALER ADDON (Optional)
# ==============================================================================

resource "oci_containerengine_addon" "cluster_autoscaler" {
  count = var.enable_autoscaling ? 1 : 0

  addon_name                       = "cluster-autoscaler"
  cluster_id                       = oci_containerengine_cluster.oke_cluster.id
  remove_addon_resources_on_delete = true

  configurations {
    key   = "numOfNodesToScaleDown"
    value = "1"
  }

  configurations {
    key   = "numOfNodesToScaleUp"
    value = "1"
  }

  configurations {
    key   = "isEnabled"
    value = "true"
  }

  depends_on = [oci_containerengine_node_pool.worker_nodes]
}