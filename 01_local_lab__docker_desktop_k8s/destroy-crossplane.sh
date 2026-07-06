#!/bin/bash

set +e

echo "========================================="
echo "Destroying Crossplane"
echo "========================================="

echo
echo "1. Cleaning platform..."
./cleanup-platform.sh

echo
echo "2. Uninstalling Crossplane..."
helm uninstall crossplane \
    -n crossplane-system

echo
echo "3. Deleting namespace..."
kubectl delete namespace crossplane-system \
    --ignore-not-found=true

echo
echo "========================================="
echo "Crossplane removed"
echo "========================================="