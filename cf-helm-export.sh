#!/bin/sh

kubectl config use-context ${KUBE_CONTEXT}

RELEASE_NAME=cf-${CF_REPO_OWNER}-${CF_REPO_NAME}-${CF_PR_NUMBER}
echo RELEASE_NAME $RELEASE_NAME

helm install ../codefresh-pr/go-hello/ --namespace=${NAMESPACE} --name ${RELEASE_NAME} --set image.repository=${IMAGE_REPOSITORY} --set image.tag=${IMAGE_TAG}

WAIT=$((SECONDS+30))
SERVICE_IP=`kubectl get svc --namespace ${NAMESPACE} ${RELEASE_NAME}-go-hello -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
while [ -z "$SERVICE_IP" -o "$SECONDS" -lt "$WAIT" ]
do
  echo -e "Service IP is still pending. Waiting..."
  SERVICE_IP=`kubectl get svc --namespace ${NAMESPACE} ${RELEASE_NAME}-go-hello -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
  sleep 5
done        

cf_export HELM_URL=$(http://$SERVICE_IP:$PORT)
echo HELM_URL "http://$SERVICE_IP:$PORT"
