Since you already have **Crossplane v2.3.3 running on Docker Desktop Kubernetes**, we can build a **100% local lab** that teaches exactly the same concepts as provisioning an Azure Blob Storage account, but without needing Azure. The key idea is to replace:

| Azure Concept      | Local Crossplane Equivalent |
| ------------------ | --------------------------- |
| Azure Subscription | Kubernetes cluster          |
| Azure Provider     | Kubernetes Provider         |
| Resource Group     | Kubernetes Namespace        |
| Storage Account    | ConfigMap                   |
| Blob Container     | Secret                      |
| Azure API          | Kubernetes API              |

You'll learn the most important Crossplane concepts: **Provider**, **ProviderConfig**, **Managed Resource**, **XRD**, **Composition**, and **Composite Resource**. ([Crossplane Docs][1])

---

# Lab Architecture

```text
Developer
    |
kubectl apply mystorage.yaml
    |
Crossplane
    |
Composite Resource (XBlobStorage)
    |
Composition
    |
+-------------------+
| Namespace         |
| ConfigMap         |
| Secret            |
+-------------------+
```

This mimics:

```text
Developer
    |
kubectl apply mystorage.yaml
    |
Crossplane
    |
BlobStorage
    |
+-------------------+
| Resource Group    |
| Storage Account   |
| Blob Container    |
+-------------------+
```

# Detailed architecture followed below:

```text
Developer

kubectl apply -f myblob.yaml

        |
        v

XBlobStorage
(platform.demo)

        |
        v

Composition
(blobstorage-local)

        |
        v

Function
(patch-and-transform)

        |
        v

provider-kubernetes

        |
        +---- Namespace
        +---- ConfigMap
        +---- Secret
```

This already teaches:

* ✅ Crossplane package management
* ✅ Providers
* ✅ ProviderConfig
* ✅ XRD
* ✅ Composition
* ✅ Pipeline mode
* ✅ Functions
* ✅ Patch-and-transform
* ✅ Composite Resources
* ✅ Managed Resources
* ✅ Reconciliation loops
* ✅ RBAC troubleshooting
* ✅ Dependency modeling
* ✅ Platform API design

---
## How this maps to a real Azure implementation

Your current local lab:

| Local Kubernetes    | Azure                  |
| ------------------- | ---------------------- |
| Namespace           | Resource Group         |
| ConfigMap           | Storage Account        |
| Secret              | Blob Container         |
| XBlobStorage        | Enterprise Storage API |
| provider-kubernetes | provider-azure         |

So when you eventually get an Azure subscription, you won't change the architecture:

```text
XBlobStorage
       |
       v
Composition
       |
       +---- ResourceGroup
       +---- StorageAccount
       +---- BlobContainer
```

You'll simply replace:

```text
provider-kubernetes
```

with:

```text
provider-azure
```


---
## Step 1: Install Crossplane

If you're using a local Kubernetes cluster:

```bash
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

helm install crossplane \
  crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace
```

---
# Step 1: Install Provider-Kubernetes

Create `provider-k8s.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.0.0
```

Install:

```bash
kubectl apply -f provider-k8s.yaml
```

Verify:

```bash
kubectl get providers
kubectl get pods -n crossplane-system
```

Expected:

```text
provider-kubernetes   True   True
```

Provider-kubernetes allows Crossplane to manage arbitrary Kubernetes resources as managed resources. ([DeepWiki][2])

---

# Step 2: Create ProviderConfig

Create `providerconfig.yaml`:

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

This tells Crossplane:

> "Use your own service account to talk to the current Kubernetes cluster."

This is similar to Azure's ProviderConfig with service principal credentials. ([DeepWiki][3])

---

# Step 3: Create an XRD

Create `xrd.yaml`:

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

  scope: Namespaced

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
```

---

# Step 4: Create Composition

Create `composition.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: blobstorage-local
spec:
  compositeTypeRef:
    apiVersion: platform.demo/v1alpha1
    kind: XBlobStorage

  resources:

  - name: namespace
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        providerConfigRef:
          name: local

        forProvider:
          manifest:
            apiVersion: v1
            kind: Namespace
            metadata:
              name: placeholder

    patches:
    - fromFieldPath: spec.storageName
      toFieldPath: spec.forProvider.manifest.metadata.name

  - name: storageaccount
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        providerConfigRef:
          name: local

        forProvider:
          manifest:
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: storage-account
              namespace: default

            data:
              tier: Standard
              replication: LRS

    patches:
    - fromFieldPath: spec.storageName
      toFieldPath: spec.forProvider.manifest.metadata.namespace

  - name: container
    base:
      apiVersion: kubernetes.crossplane.io/v1alpha2
      kind: Object
      spec:
        providerConfigRef:
          name: local

        forProvider:
          manifest:
            apiVersion: v1
            kind: Secret
            metadata:
              name: blob-container
              namespace: default

            stringData:
              container: images

    patches:
    - fromFieldPath: spec.storageName
      toFieldPath: spec.forProvider.manifest.metadata.namespace
```

Apply:

```bash
kubectl apply -f composition.yaml
```

Compositions are the core Crossplane abstraction layer that turns low-level resources into a developer-friendly API. ([Crossplane Docs][4])

---

# Step 5: Create Your "Azure Blob Storage"

Create `myblob.yaml`:

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

---

# Step 6: Observe What Crossplane Created

```bash
kubectl get xblobstorage

kubectl get namespace

kubectl get configmap -n demo-storage

kubectl get secret -n demo-storage
```

Expected:

```text
NAMESPACE
demo-storage

CONFIGMAP
storage-account

SECRET
blob-container
```

---

# What You Just Learned

When you ran:

```yaml
kind: XBlobStorage
```

Crossplane automatically created:

```text
XBlobStorage
       |
       v
Composition
       |
       +--- Namespace
       |
       +--- ConfigMap
       |
       +--- Secret
```

This is conceptually identical to:

```text
AzureBlobStorage
       |
       v
Composition
       |
       +--- ResourceGroup
       |
       +--- StorageAccount
       |
       +--- BlobContainer
```

---

# Real Azure Mapping

Later, when you get an Azure subscription, you only replace:

```text
Namespace    -> ResourceGroup
ConfigMap    -> StorageAccount
Secret       -> BlobContainer
```

Everything else remains the same:

* ✅ XRD
* ✅ Composition
* ✅ Patches
* ✅ Composite Resources
* ✅ ProviderConfig
* ✅ Reconciliation loop

This is why many platform teams recommend learning Crossplane locally first: the concepts transfer directly to AWS, Azure, and GCP. ([Kubernetes Recipe Book][5])

After you're comfortable with this lab, the next advanced exercise would be to create a `StorageClaim` API where developers can simply do:

```yaml
apiVersion: company.io/v1
kind: StorageClaim
metadata:
  name: photos
spec:
  size: small
  environment: dev
```

and have Crossplane automatically provision all the underlying resources.

[1]: https://docs.crossplane.io/latest/packages/providers/?utm_source=chatgpt.com "Providers · Crossplane v2.3"
[2]: https://deepwiki.com/crossplane-contrib/provider-kubernetes/1-overview?utm_source=chatgpt.com "crossplane-contrib/provider-kubernetes | DeepWiki"
[3]: https://deepwiki.com/crossplane-contrib/provider-kubernetes/4-usage-guides?utm_source=chatgpt.com "Usage Guides | crossplane-contrib/provider-kubernetes | DeepWiki"
[4]: https://docs.crossplane.io/latest/composition/compositions/?utm_source=chatgpt.com "Compositions · Crossplane v2.3"
[5]: https://kubernetes.recipes/recipes/configuration/kubernetes-crossplane-infrastructure-guide/?utm_source=chatgpt.com "Crossplane: Provision Cloud from Kubernetes | K8s Recipes"
