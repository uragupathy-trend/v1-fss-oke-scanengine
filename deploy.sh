#!/bin/bash
# Vision One File Security Scanner - OKE Scan Engine Deployment Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
OPERATION="deploy"
FORCE_MODE=false

# Colors
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; NC='\033[0m'

log() { echo -e "${2:-$G}[${3:-INFO}]$NC $1"; }
die() { log "$1" "$R" "ERROR"; exit 1; }

usage() {
    cat << EOF
Usage: $0 [deploy|plan|destroy] [--force]

Commands:
  deploy    Deploy OKE infrastructure (default)
  plan      Plan deployment without applying
  destroy   Destroy infrastructure
  help      Show this help

Options:
  --force   Skip confirmations (destroy only)

Examples:
  $0                  # Deploy
  $0 plan             # Plan only
  $0 destroy          # Destroy with prompts
  $0 destroy --force  # Destroy without prompts

Legacy options (deprecated):
  --plan-only         # Same as 'plan'
  --destroy           # Same as 'destroy'
EOF
}

check_prereqs() {
    log "Checking prerequisites..."
    for tool in terraform; do
        command -v "$tool" >/dev/null || die "$tool not found in PATH"
    done
    
    [[ -d "$TERRAFORM_DIR" ]] || die "Terraform directory not found: $TERRAFORM_DIR"
    
    # Optional: Check for OCI CLI if terraform configs require it
    if [[ -f "$TERRAFORM_DIR/provider.tf" ]] && grep -q "oci" "$TERRAFORM_DIR/provider.tf" 2>/dev/null; then
        command -v "oci" >/dev/null || log "OCI CLI not found - ensure authentication is configured" "$Y" "WARN"
    fi
}

deploy() {
    log "Deploying OKE infrastructure..." "$B"
    cd "$TERRAFORM_DIR"
    terraform init
    terraform plan
    terraform apply
    
    log "Deployment Summary:" "$G"
    echo "=========================="
    # Try to get common OKE outputs
    for output in cluster_id cluster_endpoint node_pool_id; do
        value=$(terraform output -raw "$output" 2>/dev/null || echo "N/A")
        echo "${output}: $value"
    done
    echo "=========================="
    log "OKE deployment complete!"
}

plan() {
    log "Planning OKE deployment..." "$B"
    cd "$TERRAFORM_DIR"
    terraform init
    terraform plan
    log "Plan completed. Run '$0 deploy' to apply changes."
}

destroy() {
    log "WARNING: This will destroy the OKE cluster and all workloads!" "$Y" "WARN"
    echo "  - OKE Cluster and Node Pools"
    echo "  - All running workloads and data"
    echo "  - Load balancers and networking"
    echo "  - Persistent volumes (if any)"
    
    if [[ "$FORCE_MODE" != "true" ]]; then
        read -p "Type 'yes' to confirm: " confirm
        [[ "$confirm" == "yes" ]] || { log "Cancelled"; exit 0; }
        read -p "Type 'DELETE' for final confirmation: " final
        [[ "$final" == "DELETE" ]] || { log "Cancelled"; exit 0; }
    fi
    
    log "Destroying OKE infrastructure..." "$Y" "WARN"
    cd "$TERRAFORM_DIR"
    terraform init
    terraform destroy
    log "All resources destroyed" "$Y" "WARN"
}

# Parse arguments (support legacy options)
while [[ $# -gt 0 ]]; do
    case $1 in
        deploy) OPERATION="deploy"; shift ;;
        plan|--plan-only) OPERATION="plan"; shift ;;
        destroy|--destroy) OPERATION="destroy"; shift ;;
        --force) FORCE_MODE=true; shift ;;
        help|--help|-h) usage; exit 0 ;;
        *) die "Unknown option: $1. Use --help for usage."; ;;
    esac
done

trap 'die "Operation interrupted"' INT TERM

log "Starting $OPERATION operation..." "$B"
check_prereqs

case $OPERATION in
    deploy) deploy ;;
    plan) plan ;;
    destroy) destroy ;;
    *) die "Invalid operation: $OPERATION" ;;
esac
