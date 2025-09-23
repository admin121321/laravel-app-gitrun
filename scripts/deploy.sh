#!/bin/bash
set -e

NAMESPACE=${1:-production}
IMAGE_TAG=${2:-latest}

echo "Deploying to namespace: $NAMESPACE"
echo "Using image tag: $IMAGE_TAG"

# Apply Kubernetes manifests
kubectl apply -f k8s/configmap.yaml -n $NAMESPACE
kubectl apply -f k8s/secrets.yaml -n $NAMESPACE
kubectl apply -f k8s/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/service.yaml -n $NAMESPACE
kubectl apply -f k8s/ingress.yaml -n $NAMESPACE

# Update image if specific tag is provided
if [ "$IMAGE_TAG" != "latest" ]; then
    kubectl set image deployment/my-app my-app=ghcr.io/your-username/my-app:$IMAGE_TAG -n $NAMESPACE
fi

# Wait for rollout to complete
kubectl rollout status deployment/my-app -n $NAMESPACE --timeout=300s

echo "Deployment completed successfully!"