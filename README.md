# EKS GPU Infrastructure

Kubernetes (EKS) infrastructure for hosting GPU workloads

## Architecture Diagrams

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

## Project Structure

## Getting Started

1. Clone the repository
2. Install prerequisites:
   - AWS CLI
   - Terraform
   - kubectl
   - A web browser for viewing the architecture diagrams

3. Configure AWS credentials
4. Deploy the infrastructure:
   ```bash
   cd terraform
   terragrunt run-all apply
   ```

## Environment Configuration

- Development: Single AZ deployment (us-west-2a)
- Production: Multi-AZ deployment (us-west-2a,b,c)

See the network diagram for detailed AZ usage visualization.
