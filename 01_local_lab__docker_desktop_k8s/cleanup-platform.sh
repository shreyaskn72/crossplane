#!/bin/bash

set +e

echo "========================================="
echo "Cleaning Crossplane Platform"
echo "========================================="

echo
echo "1. Cleaning lab resources..."
./cleanup-lab.sh

echo
echo "2. Removing XRD finalizers..."
for xrd in $(kubectl get xrd -o name 2>/dev/null); do
    echo "Removing finalizer from $xrd"
    kubectl patch $xrd \
        --type=json \
        -p='[{"op":"remove","path":"/metadata/finalizers"}]' \
        2>/dev/null
done

echo
echo "3. Deleting XRDs..."
kubectl delete xrd --all \
    --wait=false \
    2>/dev/null

sleep 5

echo
echo "4. Deleting generated CRDs..."
kubectl delete crd xblobstorages.platform.demo \
    --ignore-not-found=true \
    --force \
    --grace-period=0

echo
echo "5. Deleting functions..."
kubectl delete function function-patch-and-transform \
    --ignore-not-found=true

echo
echo "6. Removing ProviderConfig finalizers..."
for pc in $(kubectl get providerconfig -o name 2>/dev/null); do
    echo "Removing finalizer from $pc"
    kubectl patch $pc \
        --type=json \
        -p='[{"op":"remove","path":"/metadata/finalizers"}]' \
        2>/dev/null
done

echo
echo "7. Deleting ProviderConfigs..."
kubectl delete providerconfig --all \
    --wait=false \
    2>/dev/null

echo
echo "8. Deleting RBAC..."
kubectl delete clusterrolebinding provider-kubernetes-admin \
    --ignore-not-found=true

echo
echo "9. Deleting provider..."
kubectl delete provider provider-kubernetes \
    --ignore-not-found=true

echo
echo "========================================="
echo "Platform cleanup completed"
echo "========================================="