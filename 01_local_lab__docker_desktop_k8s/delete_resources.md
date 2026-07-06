Yes. Since this is a learning lab running on Docker Desktop, you can safely delete everything you created and bring the cluster back to a clean state.

I would recommend deleting in the **reverse order of creation**.

# Option 1: Delete only the lab resources (Recommended)

## Step 1: Delete the composite resource

This deletes the user-created resource and triggers Crossplane reconciliation.

```bash
kubectl delete xblobstorage my-storage
```

Verify:

```bash
kubectl get xblobstorage
kubectl get object
kubectl get ns
```

You should see the composed resources getting deleted.

---

## Step 2: Delete the Composition

```bash
kubectl delete composition blobstorage-local
```

---

## Step 3: Delete the Function

```bash
kubectl delete function function-patch-and-transform
```

---

## Step 4: Delete the XRD

First verify there are no XBlobStorage resources left:

```bash
kubectl get xblobstorage
```

Then:

```bash
kubectl delete xrd xblobstorages.platform.demo
```

Verify:

```bash
kubectl api-resources | grep blob
```

should return nothing.

---

## Step 5: Delete the ProviderConfig

```bash
kubectl delete providerconfig local
```

---

## Step 6: Delete the RBAC binding we created

Remember we created:

```bash
kubectl create clusterrolebinding provider-kubernetes-admin ...
```

Delete it:

```bash
kubectl delete clusterrolebinding provider-kubernetes-admin
```

---

## Step 7: Delete the provider

```bash
kubectl delete provider provider-kubernetes
```

Wait:

```bash
kubectl get providers
kubectl get providerrevisions
kubectl get pods -n crossplane-system
```

The provider pods should disappear.

---

# Option 2: Delete Crossplane completely

If you don't plan to use Crossplane for a while:

```bash
helm uninstall crossplane -n crossplane-system
kubectl delete namespace crossplane-system
```

Verify:

```bash
kubectl get ns
```

`crossplane-system` should be gone.

---

# Option 3: Nuclear option (reset Docker Desktop Kubernetes)

If this is only a practice cluster:

Docker Desktop → **Settings** → **Kubernetes** → **Reset Kubernetes Cluster**

This deletes absolutely everything:

* Crossplane
* Providers
* CRDs
* XRDs
* Functions
* Compositions
* RBAC
* Namespaces
* Pods
* All Kubernetes resources

---

# Recommended cleanup script for Module 1

```bash
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
```

---

## One small warning

Sometimes deleting the XRD leaves the generated CRD behind (you encountered this during debugging). If you see:

```bash
kubectl api-resources | grep blob
```

still returning:

```text
xblobstorages
```

then manually delete the CRD:

```bash
kubectl delete crd xblobstorages.platform.demo
```

This ensures your next lab starts from a completely clean state. 🚀
