# Delete the composite resource
kubectl delete xblobstorage my-storage

# Remove any orphaned composed resources
kubectl delete object --all

# Delete created namespace
kubectl delete ns demo-storage

# Delete platform definitions
kubectl delete composition blobstorage-local
kubectl delete function function-patch-and-transform
kubectl delete xrd xblobstorages.platform.demo
kubectl delete crd xblobstorages.platform.demo

# Delete provider config
kubectl delete providerconfig local

# Delete RBAC
kubectl delete clusterrolebinding provider-kubernetes-admin

# Delete provider
kubectl delete provider provider-kubernetes

# Optional: delete Crossplane itself
helm uninstall crossplane -n crossplane-system
kubectl delete namespace crossplane-system