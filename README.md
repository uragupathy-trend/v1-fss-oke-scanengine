# Vision One File Security Scanner - OKE Scanning Engine

Automated deployment of Oracle Kubernetes Engine (OKE) cluster optimized for Trend Micro Vision One File Security Scanner workloads. This solution provides scalable, localised malware scanning capabilities in Oracle Cloud Infrastructure.

## Architecture

```mermaid
flowchart TB
    subgraph VCN["OCI VCN (Virtual Cloud Network)"]
        subgraph APISubnet["API Endpoint Subnet"]
            API[OKE API Endpoint]
        end
        
        subgraph WorkerSubnet["Worker Node Subnet"]
            WN1[Worker Node 1<br/>VM.Standard.E5.Flex<br/>1 OCPU, 16GB RAM]
            WN2[Worker Node 2]
            WN3[Worker Node N...]
        end
        
        subgraph LBSubnet["Load Balancer Subnet"]
            LB[OCI Load Balancer]
        end
        
        subgraph ClusterNetwork["OKE Cluster Network"]
            subgraph PodCIDR["Pod CIDR: 10.244.0.0/16"]
                FSS1[FSS Scanner Pod]
                FSS2[FSS Scanner Pod]
                FSS3[FSS Scanner Pod]
            end
            
            subgraph ServiceCIDR["Service CIDR: 10.96.0.0/16"]
                FSSSVC[FSS Service]
            end
        end
    end
    
    subgraph External["External Components"]
        USER[Client Applications]
        V1API[Vision One API<br/>Cloud Intelligence]
        OCIR[OCIR Registry<br/>FSS Container Images]
        ObjStore[Object Storage<br/>Scan Results & Logs]
    end
    
    subgraph IAM["IAM & Security"]
        DG1[Cluster Service<br/>Dynamic Group]
        DG2[Worker Nodes<br/>Dynamic Group]
        POL1[Cluster Service Policy]
        POL2[Worker Nodes Policy]
        POL3[Autoscaling Policy]
    end
    
    USER --> LB
    LB --> FSSSVC
    FSSSVC --> FSS1
    FSSSVC --> FSS2
    FSSSVC --> FSS3
    
    FSS1 --> V1API
    FSS2 --> V1API
    FSS3 --> V1API
    
    OCIR --> FSS1
    OCIR --> FSS2
    OCIR --> FSS3
    
    FSS1 --> ObjStore
    FSS2 --> ObjStore
    FSS3 --> ObjStore
    
    WN1 --> FSS1
    WN2 --> FSS2
    WN3 --> FSS3
    
    API -.-> WN1
    API -.-> WN2
    API -.-> WN3
    
    DG1 -.-> POL1
    DG2 -.-> POL2
    DG1 -.-> POL3
    
    style USER fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style LB fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style API fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style WN1 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style WN2 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style WN3 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style FSS1 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style FSS2 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style FSS3 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style FSSSVC fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style V1API fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style OCIR fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style ObjStore fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style DG1 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style DG2 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style POL1 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style POL2 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
    style POL3 fill:#000000,stroke:#ffffff,stroke-width:4px,color:#ffffff
```

**Standard OKE Architecture Components:**

**Networking Layer:**
- **VCN (Virtual Cloud Network)**: Isolated network environment for OKE cluster
- **API Endpoint Subnet**: Hosts OKE cluster API endpoint (public/private configurable)
- **Worker Node Subnet**: Private subnet hosting Kubernetes worker nodes
- **Load Balancer Subnet**: Subnet for OCI Load Balancer services
- **Pod CIDR (10.244.0.0/16)**: Network range for Kubernetes pods
- **Service CIDR (10.96.0.0/16)**: Network range for Kubernetes services

**Compute Layer:**
- **OKE Cluster**: Managed Kubernetes control plane
- **Worker Node Pool**: Auto-scaling VM.Standard.E5.Flex instances (1 OCPU, 16GB RAM)
- **FSS Scanner Pods**: Containerized Vision One File Security Scanner instances

**Security Layer:**
- **Dynamic Groups**: Identity-based access control for cluster and worker nodes
- **IAM Policies**: Least-privilege permissions for cluster operations
- **Network Security**: Private subnets with controlled ingress/egress

**External Integration:**
- **OCIR Registry**: Private container registry for FSS images
- **Vision One API**: Cloud-based threat intelligence and scanning backend
- **Object Storage**: Persistent storage for scan results and configuration

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) - Configured with appropriate permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - For cluster management (post-deployment)

### OCI Resources
- **VCN** with proper subnets (API endpoint, worker nodes, load balancer)
- **Compartment** with required permissions
- **API keys** configured for authentication

### Permissions Required
- Manage Kubernetes clusters
- Manage container repositories
- Manage IAM policies and dynamic groups
- Manage object storage buckets
- Read VCN and subnet configurations

### Vision One Requirements
- Trend Micro Vision One account
- Vision One API token with file scanning permissions
- Vision One region configuration

## Quick Start

### 1. Configure Infrastructure

Copy and edit the configuration file:

```bash
cd FileSecurity/v1-fss-oke-scanengine
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` with your values:

```hcl
# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaas......"
user_ocid        = "ocid1.user.oc1..aaaaaaaam....."
fingerprint      = "aa:bb:cc:dd:ee:ff:gg:hh:ii:jj:kk:ll:mm:nn:oo:pp"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "ap-sydney-1"

# ==============================================================================
# INFRASTRUCTURE
# ==============================================================================
compartment_ocid           = "ocid1.compartment.oc1..aaaaaaaaws...."
vcn_ocid                  = "ocid1.vcn.oc1.ap-sydney-1.amaaaaaa......."
api_endpoint_subnet_ocid   = "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaa........"
worker_node_subnet_ocid    = "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaav.........."
load_balancer_subnet_ocid  = "ocid1.subnet.oc1.ap-sydney-1.aaaaaaaafs........"

# ==============================================================================
# CLUSTER CONFIGURATION
# ==============================================================================
cluster_name         = "fss-oke-scanengine"
kubernetes_version   = "v1.34.1"
environment         = "production"

# ==============================================================================
# NODE POOL CONFIGURATION
# ==============================================================================
node_pool_size = 1
node_shape  = "VM.Standard.E5.Flex"
node_memory_gb = 16
node_shape_ocpus = 1
node_boot_volume_size_gb = 50

# ==============================================================================
# AVAILABILITY DOMAINS
# ==============================================================================
availability_domains = ["availability_domains"]

# ==============================================================================
# SCALING CONFIGURATION
# ==============================================================================
enable_autoscaling = false
min_node_count     = 1
max_node_count     = 2

# ==============================================================================
# NODE IMAGE (Optional - leave empty for automatic selection)
# ==============================================================================

oci compute image list \
    --compartment-id ocid1.compartment.oc1..aaaaaaaaw... \
    --shape VM.Standard.E5.Flex \
    --lifecycle-state AVAILABLE \
    --operating-system "Oracle Linux" \
    --operating-system-version "8"

node_image_ocid = "ocid1.image.oc1.ap-sydney-1.aaaaaaaae......"
```

### 2. Deploy Infrastructure

The deployment script provides enhanced safety and usability features:

```bash
# Deploy OKE infrastructure (default operation)
./deploy.sh

# Or explicitly specify deploy
./deploy.sh deploy
```

### 3. Manage Infrastructure

```bash
# Deploy infrastructure
./deploy.sh deploy

# Plan deployment without applying changes
./deploy.sh plan

# Destroy infrastructure with safety confirmations
./deploy.sh destroy

# Destroy infrastructure without prompts (automated)
./deploy.sh destroy --force

# Get help
./deploy.sh help
```

The deployment script automatically:
- ✅ Checks prerequisites (Terraform, OCI CLI)
- ✅ Validates Terraform configuration exists
- ✅ Provides colored output for better visibility
- ✅ Shows deployment summary with resource details
- ✅ Includes safety confirmations for destroy operations

### 4. Deploy Vision One File Security Scanner

```bash
# Deploy with Vision One token (required)

Add V1_FSS_TOKEN='your-vision-one-token' as environment variable

./deploy-v1-fss.sh install

# Remove Vision One File Security
./deploy-v1-fss.sh uninstall
```

**Enhanced LoadBalancer Detection Features:**
- 🔍 **External IP Focus** - Efficiently checks external IP/hostname assignment
- 📍 **Multi-cloud detection** - Auto-detects OCI, AWS, GCP, Azure providers
- ⏱️ **Smart timing** - Cloud-optimized timeouts (OCI: 90s, AWS: 2min, GCP/Azure: 105s)
- 🌐 **Clean URL generation** - Generates ready-to-use gRPC endpoint
- 🔍 **gRPC connectivity testing** - Verifies gRPC port accessibility when netcat is available
- 📡 **Clear endpoint display** - Shows formatted gRPC service URL for immediate use

### 5. Access Your Cluster

```bash
kubectl get nodes
kubectl get namespaces
kubectl get pods -n visionone-filesecurity
```

## What Gets Created

### Infrastructure Components

**Compute Resources:**
- OKE cluster with Kubernetes v1.34.1
- Worker node pool with FSS-optimized configurations  
- Auto-scaling configurable (default: disabled, 1-2 nodes when enabled)
- VM.Standard.E5.Flex shapes (1 OCPU, 16GB RAM, 50GB boot volume)

**Networking:**
- Private cluster endpoints for security
- Dedicated subnets for API endpoint, workers, and load balancers
- Security groups with minimal required access

**Storage:**
- Container registry integration with OCI Registry (OCIR)
- Object Storage buckets for scan files and results
- Persistent volumes for scanning workloads

**Security:**
- IAM dynamic groups for cluster and worker nodes
- Least-privilege policies for registry and storage access
- Network policies for pod-to-pod communication
- Image pull secrets for private registry access

### Dynamic Groups and Policies

**Dynamic Groups:**
- `fss-oke-cluster-service-group` - For cluster management operations
- `fss-oke-worker-nodes-group` - For worker node operations

**Policies:**
- Container registry access (pull/push permissions)
- Object Storage access for scan files
- Cluster lifecycle management
- Networking and load balancer management

## How It Works

1. **Infrastructure Deployment** → OKE cluster with worker nodes created
2. **FSS Container Deployment** → Vision One FSS pods deployed to cluster
3. **Load Balancer Configuration** → External access configured for scanning services
4. **Service Registration** → gRPC/ICAP endpoints exposed for client connections
5. **Auto-scaling** → Pods scale based on scanning load and resource usage
6. **Scan Processing** → Files scanned using Vision One cloud intelligence
7. **Result Delivery** → Scan results returned to clients with metadata

## Testing

### Verify Deployment
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# View cluster information
kubectl cluster-info

# Check FSS namespace
kubectl get pods -n visionone-filesecurity
```

### Test Scanner Connectivity
```bash
# Check service endpoints
kubectl get svc -n visionone-filesecurity

# Test gRPC connectivity (if endpoint is available)
nc -z -w5 <EXTERNAL_IP> 50051  # gRPC port
nc -z -w5 <EXTERNAL_IP> 1344   # ICAP port
```

### Monitor Scanning Activity
```bash
# View FSS scanner logs
kubectl logs -f -n visionone-filesecurity -l app=vision-one-fss

# Monitor resource usage
kubectl top nodes
kubectl top pods -n visionone-filesecurity
```

## Troubleshooting

### Common Issues

**Deployment Failures**
- ✅ Run `./deploy.sh` to automatically check prerequisites
- ✅ Script validates Terraform and OCI CLI are installed
- ✅ Warnings shown for missing configuration values

**Cluster Access Issues**
- Verify VCN and subnet configurations
- Check security groups and route tables
- Ensure private endpoint access (VPN/bastion required for private clusters)

**FSS Scanner Issues**
- Verify Vision One API token is valid and has scanning permissions
- Check Vision One region configuration
- Ensure network connectivity to Vision One API endpoints

**LoadBalancer Detection Issues**
```bash
# Manual service status check
kubectl get svc vision-one-fss-visionone-filesecurity-scanner-lb -n visionone-filesecurity
kubectl describe svc vision-one-fss-visionone-filesecurity-scanner-lb -n visionone-filesecurity

# Check service endpoints (backend pods)
kubectl get endpoints vision-one-fss-visionone-filesecurity-scanner-lb -n visionone-filesecurity

# Verify cloud provider detection
kubectl get nodes -o jsonpath='{.items[0].spec.providerID}'
```

### Deployment Summary

After successful deployment, the script provides a summary:
```
Deployment Summary:
==========================
cluster_id: ocid1.cluster.oc1...
cluster_endpoint: https://...
node_pool_id: ocid1.nodepool.oc1...
==========================
OKE deployment complete!
```

### Monitoring and Logs

```bash
# View deployment logs
tail -f terraform/terraform.log

# Check cluster audit logs (if enabled)
oci logging search --time-start <timestamp> --log-group-id <log-group-id>

# Kubernetes troubleshooting
kubectl describe cluster
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Configuration

### Cluster Settings
- **Memory**: 16 GB per worker node
- **CPU**: 1 OCPU per worker node
- **Runtime**: Kubernetes v1.34.1
- **Shape**: VM.Standard.E5.Flex (flexible compute)
- **Auto-scaling**: Optional (default: disabled, 1-2 nodes when enabled)
- **Boot Volume**: 50 GB per worker node

### Environment Variables
The FSS scanner uses these environment variables (configured during deployment):

- `V1_API_TOKEN` - Vision One API authentication token
- `V1_REGION` - Vision One region for API endpoints
- `SCANNER_CONFIG` - Scanner-specific configuration parameters

## Security

### Network Security
- Cluster uses private endpoints only
- Worker nodes in private subnets
- Minimal security group rules
- Network policies for pod isolation

### IAM Security
- Dynamic groups with instance principal authentication
- Least-privilege policy statements
- Compartment-level resource isolation
- Audit logging for all operations

### Container Security
- Private container registry (OCIR)
- Image pull secrets for authentication
- Security contexts for pod execution
- Resource limits and requests defined

## Script Features

The optimized `deploy.sh` script provides:

### ✅ Enhanced Safety
- Prerequisites validation before execution
- Double confirmation for destroy operations
- Force mode for automated destruction
- Colored output for better visibility

### ✅ Improved Usability
- Default deploy operation (no arguments needed)
- Clear help documentation
- Deployment summary with resource details
- Error handling with descriptive messages

### ✅ Better Operations
- Automatic terraform plan generation
- Clean temporary file management
- Interrupt signal handling
- Legacy option support for backward compatibility

## Infrastructure Management

**Deploy Infrastructure:**
```bash
./deploy.sh deploy  # or just ./deploy.sh
```

**Plan Infrastructure (Preview Changes):**
```bash
./deploy.sh plan
```

**Destroy Infrastructure:**
```bash
# With safety prompts
./deploy.sh destroy

# Without prompts (for automation)
./deploy.sh destroy --force
```

The destroy operation includes safety confirmations:
1. First confirmation: Type `yes` to continue
2. Final confirmation: Type `DELETE` to confirm destruction

---

For more information about Vision One File Security and OKE, visit:
- [Vision One File Security Documentation](https://docs.trendmicro.com/en-us/documentation/article/trend-vision-one-file-security)
- [Oracle Kubernetes Engine Documentation](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm)
