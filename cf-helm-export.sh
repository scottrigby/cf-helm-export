#!/bin/sh

kubectl config use-context ${KUBE_CONTEXT}

# Defaults.
PORT=${PORT:-80}
NAMESPACE=${NAMESPACE:-default}
WAIT=${WAIT:-10}
RETRIES=${RETRIES:=10}
SCHEME=${SCHEME:-http}

# Wait for Load Balancer IP to resolve.
# @todo Support other Service types.
SERVICE_IP=""
TRIED=0
while [ -z "$SERVICE_IP" ] && [ "$TRIED" -lt "$RETRIES" ]
do
    echo "Service IP is still pending. Waiting..."
    SERVICE_IP=$(kubectl get svc --namespace ${NAMESPACE} ${SERVICE_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    sleep $WAIT
    TRIED=$(($TRIED+1))
done

# Error if IP doesn't resolve before timout.
if [ -z "$SERVICE_IP" ] ; then
    echo "Service IP didn't resolve in $RETRIES retries"
    exit 1
fi

# If we get this far, export as Codefresh ENV vars.
echo "SERVICE_IP=${SERVICE_IP}" >> ${CF_VOLUME_PATH}/env_vars_to_export
echo "Exported SERVICE_IP ${SERVICE_IP}"

echo "HELM_URL=${SCHEME}://${SERVICE_IP}:${PORT}" >> ${CF_VOLUME_PATH}/env_vars_to_export
echo "Exported HELM_URL ${HELM_URL}"
