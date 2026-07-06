# Delete user resource
kubectl delete xblobstorage my-storage

# Delete platform APIs
kubectl delete composition blobstorage-local
kubectl delete function function-patch-and-transform
kubectl delete xrd xblobstorages.platform.demo

# Delete provider config
kubectl delete providerconfig local

# Delete RBAC
kubectl delete clusterrolebinding provider-kubernetes-admin

# Delete provider
kubectl delete provider provider-kubernetes

# Optional: remove Crossplane entirely
helm uninstall crossplane -n crossplane-system
kubectl delete namespace crossplane-system