# Outputs for OKE File Security Scanning Engine
# Simplified outputs for optimized configuration

# ==============================================================================
# CLUSTER INFORMATION
# ==============================================================================

output "cluster_id" {
  description = "The OCID of the OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.id
}

output "cluster_name" {
  description = "The name of the OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.name
}

output "cluster_state" {
  description = "The state of the OKE cluster"
  value       = oci_containerengine_cluster.oke_cluster.state
}

output "kubernetes_version" {
  description = "The Kubernetes version of the cluster"
  value       = oci_containerengine_cluster.oke_cluster.kubernetes_version
}

# ==============================================================================
# NODE POOL INFORMATION
# ==============================================================================

output "node_pool_id" {
  description = "The OCID of the node pool"
  value       = oci_containerengine_node_pool.worker_nodes.id
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = oci_containerengine_node_pool.worker_nodes.name
}

output "node_pool_size" {
  description = "The number of nodes in the pool"
  value       = var.node_pool_size
}

output "node_shape" {
  description = "The shape of the worker nodes"
  value       = var.node_shape
}

# ==============================================================================
# NETWORK CONFIGURATION
# ==============================================================================

output "vcn_id" {
  description = "The OCID of the VCN"
  value       = var.vcn_ocid
}

output "network_configuration" {
  description = "Network configuration for the cluster"
  value = {
    pods_cidr               = var.cluster_pods_cidr
    services_cidr           = var.cluster_services_cidr
    api_endpoint_subnet     = var.api_endpoint_subnet_ocid
    worker_node_subnet      = var.worker_node_subnet_ocid
    load_balancer_subnet    = var.load_balancer_subnet_ocid
    endpoint_visibility     = var.cluster_endpoint_visibility
  }
}

# ==============================================================================
# ACCESS COMMANDS
# ==============================================================================

output "kubeconfig_command" {
  description = "Command to setup kubeconfig for the cluster"
  value = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint ${var.cluster_endpoint_visibility == "Public" ? "PUBLIC_ENDPOINT" : "PRIVATE_ENDPOINT"}"
}

# ==============================================================================
# DEPLOYMENT SUMMARY
# ==============================================================================

output "deployment_summary" {
  description = "Summary of the deployed OKE cluster"
  value = {
    cluster_name        = var.cluster_name
    region              = var.region
    compartment_id      = var.compartment_ocid
    kubernetes_version  = oci_containerengine_cluster.oke_cluster.kubernetes_version
    node_count          = var.node_pool_size
    node_shape          = var.node_shape
    autoscaling_enabled = var.enable_autoscaling
    endpoint_type       = var.cluster_endpoint_visibility
  }
}

output "cluster_endpoints" {
  description = "Cluster endpoint information"
  value = {
    public_endpoint  = oci_containerengine_cluster.oke_cluster.endpoints[0].public_endpoint
    private_endpoint = oci_containerengine_cluster.oke_cluster.endpoints[0].private_endpoint
  }
}

# ==============================================================================
# NEXT STEPS
# ==============================================================================

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    ========================================
    FSS OKE Scanning Engine - Next Steps
    ========================================
    
    1. Configure kubectl access:
       ${oci_containerengine_cluster.oke_cluster.id != "" ? "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.oke_cluster.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint ${var.cluster_endpoint_visibility == "Public" ? "PUBLIC_ENDPOINT" : "PRIVATE_ENDPOINT"}" : "Cluster not ready"}
    
    2. Verify cluster access:
       kubectl get nodes
    
    3. Check scanner namespace:
       kubectl get ns scanner
    
    4. Deploy your scanning workloads to the 'scanner' namespace
    
    5. Use the scanner service account for workloads requiring cluster access
    
    ========================================
  EOT
}
