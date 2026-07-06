#!/bin/bash

set +e

echo "========================================="
echo "Cleaning Crossplane Lab Resources"
echo "========================================="

echo
echo "1. Deleting XBlobStorage resources..."
kubectl delete xblobstorage --all --wait=false 2>/dev/null

sleep 5

echo
echo "2. Removing stuck XR finalizers..."
for xr in $(kubectl get xblobstorage -o name 2>/dev/null); do
    echo "Removing finalizer from $xr"
    kubectl patch $xr \
        --type=json \
        -p='[{"op":"remove","path":"/metadata/finalizers"}]' \
        2>/dev/null
done

echo
echo "3. Deleting composed Objects..."
kubectl delete object --all --wait=false 2>/dev/null

sleep 5

echo
echo "4. Removing stuck Object finalizers..."
for obj in $(kubectl get object -o name 2>/dev/null); do
    echo "Removing finalizer from $obj"
    kubectl patch $obj \
        --type=json \
        -p='[{"op":"remove","path":"/metadata/finalizers"}]' \
        2>/dev/null
done

echo
echo "5. Force deleting Objects..."
kubectl delete object --all \
    --force \
    --grace-period=0 \
    2>/dev/null

echo
echo "6. Deleting demo namespace..."
kubectl delete namespace demo-storage \
    --ignore-not-found=true

echo
echo "7. Deleting compositions..."
kubectl delete composition --all \
    --ignore-not-found=true

echo
echo "========================================="
echo "Lab cleanup completed"
echo "========================================="