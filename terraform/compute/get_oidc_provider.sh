   # get_oidc_provider.sh
   #!/bin/bash

   # Debug: Print the cluster name
   echo "Cluster Name: $1"

   CLUSTER_NAME=$1
   OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text)

   # Debug: Print the OIDC URL
   echo "OIDC URL: $OIDC_URL"

   # Extract the domain from the OIDC URL
   OIDC_DOMAIN=$(echo "$OIDC_URL" | sed 's|^https://||')

   # Debug: Print the OIDC Domain
   echo "OIDC Domain: $OIDC_DOMAIN"

   # Fetch the thumbprint using openssl
   THUMBPRINT=$(echo | openssl s_client -connect ${OIDC_DOMAIN}:443 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2 | sed 's/://g')

   # Debug: Print the Thumbprint
   echo "Thumbprint: $THUMBPRINT"

   # Output the OIDC URL and thumbprint in JSON format
   echo "{\"oidc_url\": \"$OIDC_URL\", \"thumbprint\": \"$THUMBPRINT\"}"
