#!/bin/bash
set -e

NS="visionone-filesecurity"
RELEASE="vision-one-fss"

# Detect cloud provider for optimized timing
detect_cloud_provider() {
    local provider_id=$(kubectl get nodes -o jsonpath='{.items[0].spec.providerID}' 2>/dev/null || echo "")
    case "$provider_id" in
        oci://*) echo "oci" ;;
        aws://*) echo "aws" ;;
        gce://*) echo "gcp" ;;
        azure://*) echo "azure" ;;
        *) echo "unknown" ;;
    esac
}

# Optimized LoadBalancer endpoint detection - focused on external IP assignment and URL generation
get_loadbalancer_endpoint() {
    local service_name=$1
    local namespace=$2
    local cloud_provider=$(detect_cloud_provider)
    
    echo "🔍 Checking LoadBalancer external IP assignment..."
    echo "📍 Cloud provider: $cloud_provider"
    
    # Set cloud-optimized timeouts
    local max_attempts=30
    local wait_interval=3
    case "$cloud_provider" in
        "oci") max_attempts=25; echo "⏱️  OCI LoadBalancer typically takes 30-90 seconds" ;;
        "aws") max_attempts=40; echo "⏱️  AWS ELB typically takes 1-3 minutes" ;;
        "gcp") max_attempts=35; echo "⏱️  GCP LoadBalancer typically takes 1-2 minutes" ;;
        "azure") max_attempts=35; echo "⏱️  Azure LoadBalancer typically takes 1-2 minutes" ;;
        *) echo "⏱️  Using standard timeout (90 seconds)" ;;
    esac
    
    for attempt in $(seq 1 $max_attempts); do
        # Check if LoadBalancer external IP/hostname is assigned
        local external_ip=$(kubectl get svc "$service_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        local external_hostname=$(kubectl get svc "$service_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
        
        # Determine the endpoint (IP or hostname)
        local endpoint=""
        if [[ -n "$external_ip" && "$external_ip" != "null" ]]; then
            endpoint="$external_ip"
        elif [[ -n "$external_hostname" && "$external_hostname" != "null" ]]; then
            endpoint="$external_hostname"
        fi
        
        if [[ -n "$endpoint" ]]; then
            # Get gRPC service port
            local grpc_port=$(kubectl get svc "$service_name" -n "$namespace" -o jsonpath='{.spec.ports[?(@.name=="amaas-grpc")].port}' 2>/dev/null || echo "50051")
            
            echo ""
            echo "✅ LoadBalancer external IP assigned successfully!"
            echo "🌐 External endpoint: $endpoint"
            echo ""
            echo "📡 Scanner Service URL:"
            echo "   gRPC:  $endpoint:$grpc_port"
            echo ""
            
            # Optional connectivity verification (if netcat is available)
            if command -v nc >/dev/null 2>&1; then
                echo "🔍 Testing gRPC port connectivity..."
                if nc -z -w3 "$endpoint" "$grpc_port" 2>/dev/null; then
                    echo "✅ gRPC port ($grpc_port) is accessible"
                else
                    echo "⚠️  gRPC port ($grpc_port) not yet accessible (service may still be starting)"
                fi
                echo ""
            fi
            
            echo "🎉 Vision One File Security Scanner is ready!"
            echo "📋 Use this gRPC endpoint to configure your scanning clients."
            return 0
        fi
        
        echo "⏳ [$attempt/$max_attempts] Waiting for external IP assignment..."
        sleep $wait_interval
    done
    
    # Timeout reached - provide troubleshooting guidance
    echo ""
    echo "❌ LoadBalancer external IP not assigned within timeout period"
    echo ""
    echo "🔧 Troubleshooting steps:"
    echo "   1. Check service status:"
    echo "      kubectl get svc $service_name -n $namespace"
    echo "   2. Describe service for events:"
    echo "      kubectl describe svc $service_name -n $namespace"
    echo "   3. Check LoadBalancer provisioning:"
    echo "      kubectl get events -n $namespace --sort-by=.metadata.creationTimestamp"
    echo ""
    
    return 1
}

install() {
    # Check prerequisites (kubectl, helm)
    command -v kubectl helm >/dev/null || { echo "Error: kubectl and helm are required"; exit 1; }
    
    # Get token from environment variable
    if [ -z "$V1_FSS_TOKEN" ]; then
        echo "Error: V1_FSS_TOKEN environment variable is required"
        echo "Usage: V1_FSS_TOKEN='your-vision-one-token' $0 install"
        echo "Example: V1_FSS_TOKEN='abcd1234-5678-90ef-ghij-klmnopqrstuv' $0 install"
        exit 1
    fi
    
    TOKEN="$V1_FSS_TOKEN"
    echo "Using Vision One token from V1_FSS_TOKEN environment variable"
    
    # Create namespace and secrets
    kubectl create namespace $NS --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret generic token-secret --from-literal=registration-token="$TOKEN" -n $NS --dry-run=client -o yaml | kubectl apply -f -
    kubectl create secret generic device-token-secret -n $NS --dry-run=client -o yaml | kubectl apply -f -
    
    # Install helm chart
    helm repo add visionone-filesecurity https://trendmicro.github.io/visionone-file-security-helm/ --force-update
    helm install $RELEASE visionone-filesecurity/visionone-filesecurity -n $NS --wait
    
    kubectl apply -f visionone-filesecurity-scanner-lb.yaml
    
    echo "✓ Vision One File Security deployed successfully"
    
    # Optimized LoadBalancer endpoint detection
    get_loadbalancer_endpoint "${RELEASE}-visionone-filesecurity-scanner-lb" "$NS"
}

uninstall() {
    helm uninstall $RELEASE -n $NS 2>/dev/null || true
    kubectl delete namespace $NS --ignore-not-found
    echo "✓ Vision One File Security removed"
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 [install|uninstall]" ;;
esac
