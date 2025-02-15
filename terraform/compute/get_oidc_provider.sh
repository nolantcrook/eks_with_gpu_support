   # get_oidc_provider.sh
   #!/bin/bash

   # Redirect debug output to stderr
   echo "Cluster Name: $1" >&2

   CLUSTER_NAME=$1
   OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query "cluster.identity.oidc.issuer" --output text --region us-west-2)

   # Redirect debug output to stderr
   echo "OIDC URL: $OIDC_URL" >&2

   # Correctly extract the domain from the OIDC URL
   OIDC_DOMAIN=$(echo "$OIDC_URL" | sed -E 's|^https://([^/]+).*|\1|')

   # Remove "https://" from the OIDC URL
   OIDC_URL_NO_HTTPS=$(echo "$OIDC_URL" | sed 's|^https://||')

   # Redirect debug output to stderr
   echo "OIDC URL without https: $OIDC_URL_NO_HTTPS" >&2

   # Fetch the thumbprint using openssl
   THUMBPRINT=$(echo | openssl s_client -connect ${OIDC_DOMAIN}:443 2>/dev/null | openssl x509 -fingerprint -noout | cut -d'=' -f2 | sed 's/://g')

   # Redirect debug output to stderr
   echo "Thumbprint: $THUMBPRINT" >&2

   # Output the OIDC URL without "https://" and thumbprint in JSON format
   echo "{\"oidc_url\": \"$OIDC_URL_NO_HTTPS\", \"thumbprint\": \"$THUMBPRINT\"}"
