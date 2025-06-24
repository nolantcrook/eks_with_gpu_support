# Migration Guide: EKS Cluster Logging Optimization

This guide helps you migrate existing EKS cluster deployments to use the new cost-optimized logging configuration.

## Before Migration

Your current configuration likely looks like this:

```hcl
resource "aws_eks_cluster" "eks_gpu" {
  # ... other configuration ...

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
```

## After Migration

Update your configuration to use the new module variables:

```hcl
module "eks_cluster" {
  source = "./cluster_module"

  cluster_name = "eks-gpu"
  environment  = "dev"

  # New cost-optimized defaults
  enabled_cluster_log_types = ["audit"]  # Only audit logs
  cloudwatch_log_retention_days = 1      # 1 day retention

  # ... other required variables ...
}
```

## Step-by-Step Migration

### 1. Update Module Configuration

Add the new variables to your module call:

```hcl
module "eks_cluster" {
  source = "./cluster_module"

  cluster_name = "eks-gpu"
  environment  = "dev"

  # Add these new variables
  enabled_cluster_log_types = ["audit"]
  cloudwatch_log_retention_days = 1

  # Existing variables
  private_subnet_ids = var.private_subnet_ids
  public_subnet_ids  = var.public_subnet_ids
  cluster_security_group_id = var.cluster_security_group_id
}
```

### 2. Plan the Changes

Run `terraform plan` to see what changes will be made:

```bash
terraform plan
```

You should see:
- EKS cluster logging configuration changes
- New CloudWatch log group creation
- Log retention policy updates

### 3. Apply the Changes

Run `terraform apply` to apply the changes:

```bash
terraform apply
```

**Note**: EKS cluster updates are performed in-place and should not cause downtime.

### 4. Verify the Changes

Check that the logging configuration has been updated:

```bash
aws eks describe-cluster --name eks-gpu-dev --region us-west-2 --query 'cluster.logging'
```

You should see only `audit` logs enabled.

## Environment-Specific Configurations

### Development Environment
```hcl
enabled_cluster_log_types = ["audit"]
cloudwatch_log_retention_days = 1
```

### Production Environment
```hcl
enabled_cluster_log_types = ["audit", "api"]
cloudwatch_log_retention_days = 7
```

### Debugging Environment
```hcl
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_retention_days = 3
```

## Cost Impact

After migration, you should see a significant reduction in CloudWatch costs:

- **Before**: ~$0.53/day
- **After**: ~$0.05-0.10/day
- **Savings**: 90-95% reduction

## Troubleshooting

### If Terraform Plan Shows No Changes

If `terraform plan` shows no changes, it might be because:
1. The cluster already has the desired configuration
2. The module variables are not being passed correctly

Check your module configuration and ensure the variables are properly set.

### If You Need to Re-enable Full Logging

For debugging purposes, you can temporarily re-enable full logging:

```hcl
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_retention_days = 3
```

Remember to change it back to the cost-optimized configuration after debugging.

## Rollback Plan

If you need to rollback, you can:

1. Update the variables back to full logging
2. Run `terraform apply` again
3. The cluster will be updated in-place

```hcl
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
cloudwatch_log_retention_days = 3
```
