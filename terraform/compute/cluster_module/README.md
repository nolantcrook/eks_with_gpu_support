# EKS Cluster Module

This Terraform module creates an EKS cluster with configurable logging to optimize CloudWatch costs.

## Features

- **Cost-Optimized Logging**: Default configuration minimizes CloudWatch costs
- **Configurable Log Types**: Choose which EKS log types to enable
- **Configurable Retention**: Set CloudWatch log retention period
- **Automatic Log Group Management**: Creates and manages CloudWatch log groups

## Usage

```hcl
module "eks_cluster" {
  source = "./cluster_module"

  cluster_name = "my-cluster"
  environment  = "dev"

  # Optional: Configure logging (defaults to cost-optimized settings)
  enabled_cluster_log_types = ["audit"]  # Only audit logs enabled by default
  cloudwatch_log_retention_days = 1      # 1 day retention by default

  private_subnet_ids = ["subnet-123", "subnet-456"]
  public_subnet_ids  = ["subnet-789", "subnet-012"]
  cluster_security_group_id = "sg-12345678"
}
```

## Logging Configuration

### Available Log Types

- `api` - Kubernetes API server logs
- `audit` - Kubernetes audit logs (recommended for security)
- `authenticator` - Authentication logs
- `controllerManager` - Kubernetes controller manager logs
- `scheduler` - Kubernetes scheduler logs

### Cost Optimization

**Default Configuration (Cost-Optimized):**
- Only `audit` logs enabled
- 1-day retention period
- Estimated cost: ~$0.05-0.10/day

**Full Logging Configuration:**
- All log types enabled
- 3-day retention period
- Estimated cost: ~$0.50-0.60/day

### Environment-Specific Recommendations

**Development:**
```hcl
enabled_cluster_log_types = ["audit"]
cloudwatch_log_retention_days = 1
```

**Production:**
```hcl
enabled_cluster_log_types = ["audit", "api"]
cloudwatch_log_retention_days = 7
```

**Debugging:**
```hcl
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_retention_days = 3
```

## Outputs

- `cluster_name` - Name of the EKS cluster
- `cluster_arn` - ARN of the EKS cluster
- `cluster_endpoint` - Endpoint URL for the EKS cluster
- `cluster_security_group_id` - Security group ID of the cluster
- `cloudwatch_log_group_arn` - ARN of the CloudWatch log group
- `cloudwatch_log_group_name` - Name of the CloudWatch log group

## Cost Impact

The default configuration reduces CloudWatch costs by approximately 90-95% compared to full logging:

- **Before**: ~$0.53/day (all logs enabled)
- **After**: ~$0.05-0.10/day (audit logs only)

## Migration from Existing Clusters

If you have an existing cluster with full logging enabled, you can update it by:

1. Updating the Terraform configuration with the new variables
2. Running `terraform plan` to see the changes
3. Running `terraform apply` to apply the changes

The EKS cluster will be updated in-place without downtime.
