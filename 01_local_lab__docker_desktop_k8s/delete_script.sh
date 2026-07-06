
#!/bin/bash

set +e

echo "======================================"
echo "Deleting Crossplane demo resources"
echo "======================================"

echo
echo "1. Deleting XBlobStorage resources..."
kubectl delete xblobstorage --all --wait=false 2>/dev/null

sleep 5

echo
echo "2. Removing stuck XR finalizers..."
for xr in $(kubectl get xblobstorage -o name 2>/dev/null); do
  kubectl patch $xr \
    --type=json \
    -p='[{"op":"remove","path":"/metadata/finalizers"}]' \
    2>/dev/null
done

echo
echo "3. Deleting composed resources..."
kubectl delete object --all --wait=false 2>/dev/null

sleep 3

echo
echo "4. Removing stuck Object finalizers..."
for obj in $(kubectl get object -o name 2>/dev/null); do
  kubectl patch $obj \
    --type=json \
    -p='[{"op":"remove","path":"/metadata/finalizers"}]' \
    2>/dev/null
done

echo
echo "5. Deleting demo namespaces..."
kubectl delete ns demo-storage --ignore-not-found=true

echo
echo "6. Deleting platform APIs..."
kubectl delete composition blobstorage-local --ignore-not-found=true
kubectl delete function function-patch-and-transform --ignore-not-found=true
kubectl delete xrd xblobstorages.platform.demo --ignore-not-found=true
kubectl delete crd xblobstorages.platform.demo --ignore-not-found=true

echo
echo "7. Deleting provider config..."
kubectl delete providerconfig local --ignore-not-found=true

echo
echo "8. Deleting RBAC..."
kubectl delete clusterrolebinding provider-kubernetes-admin \
  --ignore-not-found=true

echo
echo "9. Deleting provider..."
kubectl delete provider provider-kubernetes \
  --ignore-not-found=true

echo
echo "10. Optional: Remove Crossplane"
read -p "Delete Crossplane itself? (y/N): " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    helm uninstall crossplane -n crossplane-system
    kubectl delete namespace crossplane-system \
      --ignore-not-found=true
fi

echo
echo "======================================"
echo "Cleanup complete"
echo "======================================"

