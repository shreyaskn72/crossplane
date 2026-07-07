# Crossplane Local Lab on Docker Desktop Kubernetes

## Learning Azure Blob Storage Concepts Without an Azure Subscription

---

# 1. What is Crossplane?

Crossplane is an open-source control plane framework used to create and manage infrastructure using Kubernetes APIs.

Instead of writing:

```bash
terraform apply
```

you create Kubernetes resources:

```yaml
apiVersion: platform.demo/v1alpha1
kind: XBlobStorage
```

and Crossplane automatically provisions the required infrastructure.

---

# 2. How Crossplane Works

Crossplane extends Kubernetes using several layers:

```
Developer
    |
    v
Claim / Composite Resource
    |
    v
Composition
    |
    v
Functions
    |
    v
Managed Resources
    |
    v
Cloud Provider / Kubernetes
```

---

# 3. Crossplane Concepts

| Concept          | Purpose                                 |
| ---------------- | --------------------------------------- |
| Provider         | Installs support for a platform         |
| ProviderConfig   | Authentication details                  |
| Managed Resource | Represents actual infrastructure        |
| XRD              | Defines a custom platform API           |
| Composition      | Describes how infrastructure is created |
| Function         | Performs patching/transformation        |
| XR               | Instance of the platform API            |

---

# 4. Why Build This Lab?

We don't have an Azure subscription.

Therefore we simulate Azure resources locally.

---

## Real Azure

```
BlobStorage
     |
     +-- Resource Group
     +-- Storage Account
     +-- Blob Container
```

---

## Local Kubernetes Equivalent

```
XBlobStorage
     |
     +-- Namespace
     +-- ConfigMap
     +-- Secret
```

The concepts are identical.

---

# 5. Architecture

```
User creates:

XBlobStorage
       |
       v
Composition
       |
       v
Patch-and-Transform Function
       |
       v
Provider-Kubernetes
       |
       +---- Namespace
       +---- ConfigMap
       +---- Secret
```

---

# 6. Install Crossplane

Add Helm repo:

```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
```

Install Crossplane:

```bash
helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace
```

Verify:

```bash
kubectl get pods -n crossplane-system
```

Expected:

```
crossplane
crossplane-rbac-manager
```

---

# 7. Install Provider Kubernetes

File:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.0.0
```

Apply:

```bash
kubectl apply -f provider-k8s.yaml
```

Verify:

```bash
kubectl get providers
kubectl get providerrevisions
kubectl get pods -n crossplane-system
```

---

# 8. Create ProviderConfig

File:

```yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: local

spec:
  credentials:
    source: InjectedIdentity
```

Apply:

```bash
kubectl apply -f providerconfig.yaml
```

Verify:

```bash
kubectl get providerconfigs
```

---

# 9. Install Function Patch and Transform

File:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: Function
metadata:
  name: function-patch-and-transform

spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.8.2
```

Apply:

```bash
kubectl apply -f function.yaml
```

Verify:

```bash
kubectl get functions
```

Expected:

```
INSTALLED=True
HEALTHY=True
```

---

# 10. Create XRD

File:

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: xblobstorages.platform.demo

spec:
  group: platform.demo

  names:
    kind: XBlobStorage
    plural: xblobstorages

  scope: Cluster

  versions:
  - name: v1alpha1
    served: true
    referenceable: true

    schema:
      openAPIV3Schema:
        type: object

        properties:
          spec:
            type: object

            properties:
              location:
                type: string

              storageName:
                type: string

            required:
            - location
            - storageName
```

Apply:

```bash
kubectl apply -f xrd.yaml
```

Verify:

```bash
kubectl get xrd
kubectl api-resources | grep blob
```

---

# 11. Create Composition

The composition creates:

* Namespace
* ConfigMap
* Secret

Apply:

```bash
kubectl apply -f composition.yaml
```

Verify:

```bash
kubectl get compositions
kubectl get composition blobstorage-local -o yaml
```

---

# 12. Create XBlobStorage

File:

```yaml
apiVersion: platform.demo/v1alpha1
kind: XBlobStorage

metadata:
  name: my-storage

spec:
  location: eastus
  storageName: demo-storage
```

Apply:

```bash
kubectl apply -f myblob.yaml
```

Verify:

```bash
kubectl get xblobstorage
```

Expected:

```
NAME         SYNCED   READY
my-storage   True     True
```

---

# 13. Verify Created Resources

Verify namespace:

```bash
kubectl get ns
```

Expected:

```
demo-storage
```

Verify ConfigMap:

```bash
kubectl get configmap -n demo-storage
```

Expected:

```
storage-account
```

Verify Secret:

```bash
kubectl get secret -n demo-storage
```

Expected:

```
blob-container
```

Verify Crossplane objects:

```bash
kubectl get object
```

Expected:

```
Namespace
ConfigMap
Secret
```

---

# 14. RBAC Fix

Provider Kubernetes requires cluster permissions.

Find service account:

```bash
kubectl get sa -n crossplane-system
```

Grant permissions:

```bash
kubectl create clusterrolebinding provider-kubernetes-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=crossplane-system:<provider-service-account>
```

Example:

```bash
kubectl create clusterrolebinding provider-kubernetes-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=crossplane-system:provider-kubernetes-fd54bbc7f877
```

---

# 15. Useful Debugging Commands

## Check providers

```bash
kubectl get providers
kubectl describe provider provider-kubernetes
```

---

## Check provider revisions

```bash
kubectl get providerrevisions
```

---

## Check functions

```bash
kubectl get functions
```

---

## Check compositions

```bash
kubectl get compositions
kubectl get composition blobstorage-local -o yaml
```

---

## Check XRD

```bash
kubectl get xrd
kubectl describe xrd xblobstorages.platform.demo
```

---

## Check XR

```bash
kubectl get xblobstorage
kubectl describe xblobstorage my-storage
kubectl get xblobstorage my-storage -o yaml
```

---

## Check composed resources

```bash
kubectl get object
kubectl describe object <name>
```

---

## Check Crossplane logs

```bash
kubectl logs \
  deployment/crossplane \
  -n crossplane-system
```

---

## Restart Crossplane

```bash
kubectl rollout restart deployment crossplane \
  -n crossplane-system

kubectl rollout restart deployment crossplane-rbac-manager \
  -n crossplane-system
```

---

# 16. Common Errors

---

## Error

```
spec.resources unknown
```

### Fix

Install:

```
function-patch-and-transform
```

and use:

```yaml
mode: Pipeline
```

---

## Error

```
cannot apply cluster scoped resource
for namespaced composite
```

### Fix

Use:

```yaml
scope: Cluster
```

in the XRD.

---

## Error

```
scope immutable
```

### Fix

Delete and recreate:

```bash
kubectl delete xrd
kubectl delete crd
kubectl apply
```

---

## Error

```
cannot add composite resource finalizer
```

### Fix

Restart Crossplane:

```bash
kubectl rollout restart deployment crossplane \
-n crossplane-system
```

---

## Error

```
forbidden
cannot get namespaces
```

### Fix

Grant cluster-admin to provider-kubernetes.

---

# 17. What We Learned

We successfully learned:

* Installing Crossplane
* Installing Providers
* ProviderConfig
* XRD
* Composition
* Function Pipelines
* Patch and Transform
* Composite Resources
* Reconciliation
* Provider RBAC
* Debugging
* Crossplane Architecture

---

# 18. Mapping To Real Azure

| Local Lab           | Azure                  |
| ------------------- | ---------------------- |
| Namespace           | Resource Group         |
| ConfigMap           | Storage Account        |
| Secret              | Blob Container         |
| XBlobStorage        | Azure Blob Storage API |
| Provider Kubernetes | Provider Azure         |
| Docker Desktop      | Azure Subscription     |

---

# Final Architecture

```
Developer
      |
      v
XBlobStorage
      |
      v
Composition
      |
      v
Function Patch-and-Transform
      |
      v
Provider-Kubernetes
      |
      +---- Namespace
      +---- ConfigMap
      +---- Secret
```

Congratulations! You have successfully built your first Internal Developer Platform API using Crossplane.


If you want to delete all resources created after practice you can follow this [delete_guide](delete_resources.md)