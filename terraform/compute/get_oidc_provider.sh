   # get_oidc_provider.sh
   #!/bin/bash
   CLUSTER_NAME=$1
   OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text)
   echo "{\"oidc_url\": \"$OIDC_URL\"}"
