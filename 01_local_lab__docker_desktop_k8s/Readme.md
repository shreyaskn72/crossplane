We can build a **100% local lab** that teaches exactly the same concepts as provisioning an Azure Blob Storage account, but without needing Azure. The key idea is to replace:

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
## Runbook

To continue further please refer [runbook](./runbook.md)
