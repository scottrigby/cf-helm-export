#!/bin/sh

# Validate required args.
for var in KUBE_CONTEXT SERVICE_NAME; do
  if [ -z "${!var}" ]; then
      echo "$var ENV var is required"
      exit 1
  fi
done

kubectl config use-context ${KUBE_CONTEXT}

# Defaults.
PORT=${PORT:-80}
NAMESPACE=${NAMESPACE:-default}
TIMEOUT=${TIMEOUT:=60}
WAIT=${WAIT:-10}
SCHEME=${SCHEME:-http}

# Wait for Load Balancer IP to resolve.
# @todo Support other Service types.
TIME=$((SECONDS+$TIMEOUT))
SERVICE_IP=""
while [ -z "$SERVICE_IP" ] && [ "$SECONDS" -lt "$TIME" ]
do
    echo "Service IP is still pending. Waiting..."
    SERVICE_IP=$(kubectl get svc --namespace ${NAMESPACE} ${SERVICE_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    sleep $WAIT
done

# Error if IP doesn't resolve before timout.
if [ -z "$SERVICE_IP" ]; then
    echo timed out in $TIME seconds
    exit 1
fi

# If we get this far, export as Codefresh ENV vars.
echo "SERVICE_IP=${SERVICE_IP}" >> ${CF_VOLUME_PATH}/env_vars_to_export
echo "Exported SERVICE_IP ${SERVICE_IP}"

echo "HELM_URL=${SCHEME}://${SERVICE_IP}:${PORT}" >> ${CF_VOLUME_PATH}/env_vars_to_export
echo "Exported HELM_URL ${HELM_URL}"
