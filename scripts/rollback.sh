#!/bin/bash
set -e

NAMESPACE=${1:-production}

echo "Rolling back deployment in namespace: $NAMESPACE"

kubectl rollout undo deployment/my-app -n $NAMESPACE
kubectl rollout status deployment/my-app -n $NAMESPACE

echo "Rollback completed successfully!"