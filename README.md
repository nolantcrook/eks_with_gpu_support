# EKS GPU Infrastructure

A comprehensive AWS EKS infrastructure repository for hosting GPU workloads, AI/ML applications, and enterprise services using Terraform and Terragrunt.

## 🏗️ Architecture Overview

This repository provides a complete, production-ready EKS infrastructure with the following capabilities:

- **GPU-enabled compute nodes** for AI/ML workloads
- **Multi-environment support** (dev/prod) with proper isolation
- **Modular Terraform architecture** for easy management and scaling
- **CI/CD pipeline** with Jenkins for automated deployments
- **RAG (Retrieval-Augmented Generation)** infrastructure for AI applications
- **Comprehensive networking** with security groups and load balancers
- **Storage solutions** for data persistence and management

## 📊 Architecture Diagrams

### Network Architecture
This diagram shows the overall network architecture including VPC, subnets, and security groups.

To view the network diagram:
1. Open `docs/network-diagram.html` in a web browser
2. The diagram shows:
   - VPC and subnet layout
   - Security group configurations
   - Load balancer and WAF setup
   - Development vs Production AZ usage

### Port Routing
This diagram shows the detailed port routing from the ALB to the ArgoCD service.

To view the port routing diagram:
1. Open `docs/port-routing-diagram.html` in a web browser
2. The diagram shows:
   - DNS resolution flow
   - Load balancer port configuration
   - NGINX ingress controller setup
   - Internal Kubernetes service routing
   - Port mappings at each step

## 🏛️ Infrastructure Components

### Terraform Modules

#### 🏗️ Foundation (`terraform/foundation/`)
- Core AWS infrastructure setup
- IAM roles and policies
- Basic security configurations

#### 💾 Storage (`terraform/storage/`)
- EBS volumes for persistent storage
- S3 buckets for object storage
- Backup and snapshot configurations

#### 🌐 Networking (`terraform/networking/`)
- VPC and subnet configurations
- Security groups and NACLs
- Load balancers and routing
- Multi-AZ setup for high availability

#### 🖥️ Compute (`terraform/compute/`)
- EKS cluster configuration
- GPU-enabled node groups
- Auto-scaling configurations
- Bastion host for secure access
- IAM roles for various applications:
  - DeepSeek AI service
  - Flask API applications
  - Hauliday service
  - InvokeAI headless
  - Knowledge base demo
  - Langchain applications
  - TCO demo

#### 🤖 RAG (`terraform/rag/`)
- Retrieval-Augmented Generation infrastructure
- OpenSearch cluster for vector search
- Auto-ingestion pipelines
- Index creation and management
- IAM roles for RAG applications

#### 📞 Call Center (`terraform/call_center/`)
- Call center infrastructure
- Communication services
- Integration with other components

## 🌍 Environment Configuration

### Development Environment
- **Location**: `environments/dev/`
- **Deployment**: Single AZ deployment (us-west-2a)
- **Resources**: Smaller instance sizes for cost optimization
- **Purpose**: Development and testing

### Production Environment
- **Location**: `environments/prod/`
- **Deployment**: Multi-AZ deployment (us-west-2a,b,c)
- **Resources**: High-availability with redundancy
- **Purpose**: Production workloads

## 🚀 CI/CD Pipeline

The repository includes a comprehensive Jenkins pipeline (`Jenkinsfile`) with the following features:

### Pipeline Parameters
- **Environment Selection**: Choose between dev/prod
- **Action Selection**: Apply or destroy infrastructure
- **Auto-Approve**: Optional automatic approval
- **Module Selection**: Choose which components to deploy:
  - Foundation
  - Storage
  - Networking
  - Compute
  - RAG
  - Call Center

### Pipeline Stages
1. **Validation**: Ensures at least one module is selected
2. **Checkout**: Retrieves the latest code
3. **kubectl Configuration**: Sets up Kubernetes access
4. **Infrastructure Deployment**: Applies selected modules in order
5. **Destruction**: Safely destroys infrastructure when needed

## 📦 Supported Applications

The infrastructure supports various AI/ML and enterprise applications:

- **DeepSeek AI**: Advanced AI processing
- **InvokeAI**: Stable Diffusion and image generation
- **Knowledge Base Demo**: RAG-powered knowledge systems
- **Langchain Applications**: LLM integration and processing
- **Hauliday Service**: Custom business application
- **TCO Demo**: Total Cost of Ownership analysis
- **Flask API**: Web API services

## 🛠️ Prerequisites

Before deploying this infrastructure, ensure you have:

- **AWS CLI** configured with appropriate permissions
- **Terraform** (>= 1.0)
- **Terragrunt** for configuration management
- **kubectl** for Kubernetes management
- **Jenkins** for CI/CD pipeline
- **Docker** for containerized applications
- **A web browser** for viewing architecture diagrams

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd eks_stable_diffusion
```

### 2. Configure AWS Credentials
```bash
aws configure
```

### 3. Review Environment Configuration
```bash
# Check development environment
ls environments/dev/

# Check production environment
ls environments/prod/
```

### 4. Deploy Using Jenkins Pipeline
1. Access your Jenkins instance
2. Create a new pipeline job
3. Point to this repository's Jenkinsfile
4. Configure the pipeline parameters
5. Execute the pipeline

### 5. Manual Deployment (Alternative)
```bash
# Navigate to the desired terraform module
cd terraform/foundation

# Initialize Terraform
terragrunt init

# Plan the deployment
terragrunt plan

# Apply the changes
terragrunt apply
```

## 🔧 Configuration Management

The infrastructure uses Terragrunt for configuration management:

- **DRY Principle**: Avoid repeating Terraform code
- **Environment-specific configs**: Separate configurations for dev/prod
- **Remote state management**: Centralized state storage
- **Dependency management**: Automatic handling of module dependencies

## 📈 Monitoring and Logging

The infrastructure includes comprehensive monitoring:

- **CloudWatch**: AWS native monitoring
- **EKS logging**: Kubernetes cluster logs
- **Application logs**: Centralized logging for applications
- **Metrics collection**: Performance and resource utilization

## 🔐 Security Features

- **IAM roles**: Least privilege access patterns
- **Security groups**: Network-level security
- **Encryption**: Data encryption at rest and in transit
- **Secret management**: Secure handling of sensitive data
- **Network isolation**: Proper subnet and VPC configurations

## 🏷️ Resource Tagging

All resources are properly tagged for:
- Environment identification
- Cost tracking
- Resource management
- Compliance requirements

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the terms specified in the LICENSE file.

## 📞 Support

For questions or issues:
1. Check the architecture diagrams in the `docs/` directory
2. Review the module-specific documentation
3. Check the Jenkins pipeline logs for deployment issues
4. Review AWS CloudWatch logs for application issues
