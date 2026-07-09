Absolutely. I would write this differently from the QA runbook. A **Developer Runbook** should teach **why** each concept exists, **what changes were made**, **how to test it**, and **what to observe**. It should read like a hands-on lab manual.

---

# Module 2 Developer Runbook

## Objective

In Module 1, we learned how to create a basic Crossplane Composition that provisions three Kubernetes resources:

* Namespace (Resource Group equivalent)
* ConfigMap (Storage Account equivalent)
* Secret (Blob Container equivalent)

In Module 2, we enhance the Composition using some of the most commonly used Crossplane features.

---

# Concepts Covered

| Step | Concept             | Purpose                                                        |
| ---- | ------------------- | -------------------------------------------------------------- |
| 1    | Patching            | Copy values from the Composite Resource into managed resources |
| 2    | Map Transforms      | Convert user-friendly values into platform-specific values     |
| 3    | Multiple Transforms | Apply transformations to multiple fields                       |
| 4    | Combine Patches     | Generate new values by combining multiple inputs               |
| 5    | Connection Secrets  | Publish connection information for applications                |

> **Note:** Traditional `readinessChecks` are part of the legacy Composition model. Since this lab uses **Crossplane v2 Pipeline Compositions**, readiness is handled differently and is not implemented here.

---

# Prerequisites

Verify Crossplane is running.

```bash
kubectl get pods -n crossplane-system
```

Verify Provider.

```bash
kubectl get providers
```

Verify Function.

```bash
kubectl get functions
```

Verify ProviderConfig.

```bash
kubectl get providerconfig
```

---

# Deploy Platform

```bash
kubectl apply -f xrd.yaml
kubectl apply -f function.yaml
kubectl apply -f providerconfig.yaml
kubectl apply -f composition.yaml
```

Verify

```bash
kubectl get xrd
kubectl get composition
kubectl get functions
```

---

# Create Storage

Apply the composite resource.

```bash
kubectl apply -f myblob.yaml
```

Verify

```bash
kubectl get xblobstorage
```

Expected

```text
READY=True
SYNCED=True
```

---

# Concept 1 — Patching

## Goal

Copy values from the Composite Resource into composed resources.

Input

```yaml
spec:
  storageName: demo-storage
```

Composition

```yaml
fromFieldPath: spec.storageName
toFieldPath: spec.forProvider.manifest.metadata.name
```

Result

```text
Namespace:
demo-storage
```

Verify

```bash
kubectl get ns
```

---

# Concept 2 — Map Transform

## Goal

Allow developers to use simple values while the platform translates them.

Developer writes

```yaml
size: small
```

Crossplane converts it to

```text
Standard_LRS
```

Verify

```bash
kubectl get configmap storage-account \
-n demo-storage-dev \
-o yaml
```

Expected

```yaml
sku: Standard_LRS
```

---

# Concept 3 — Multiple Transforms

## Goal

Transform more than one field.

Developer writes

```yaml
environment: dev
```

Crossplane converts it to

```text
development
```

Verify

```bash
kubectl get configmap storage-account \
-n demo-storage-dev \
-o yaml
```

Expected

```yaml
environment: development
```
[concept 3 deep dive](./concept_3_testing.md)
---

# Concept 4 — Combine Patches

## Goal

Generate values dynamically from multiple inputs.

Developer provides

```yaml
storageName: demo-storage
environment: dev
```

Crossplane combines them into

```text
demo-storage-dev
```

The generated value is used as the namespace.

Verify

```bash
kubectl get ns
```

Expected

```text
demo-storage-dev
```

Also verify

```bash
kubectl get configmap storage-account \
-n demo-storage-dev

kubectl get secret blob-container \
-n demo-storage-dev
```

Both resources should exist inside the generated namespace.

[concept 4 deep dive](./concept4_testing.md)

---
# concept 5: Readiness probe (theory only)

[concept 5 theory](./concept_5_explanation.md)

# Concept 6 — Connection Secrets

## Goal

Generate application connection information.

Our Secret contains

```text
Account Name
Endpoint
Environment
```

Verify

```bash
kubectl get secret blob-container \
-n demo-storage-dev \
-o yaml
```

Decode values

```bash
kubectl get secret blob-container \
-n demo-storage-dev \
-o jsonpath='{.data.accountName}' \
| base64 --decode
```

Expected

```text
demo-storage
```

Decode endpoint

```bash
kubectl get secret blob-container \
-n demo-storage-dev \
-o jsonpath='{.data.endpoint}' \
| base64 --decode
```

Expected

```text
https://demo-storage.blob.core.windows.net
```

Decode environment

```bash
kubectl get secret blob-container \
-n demo-storage-dev \
-o jsonpath='{.data.environment}' \
| base64 --decode
```

Expected

```text
development
```
[concept 6 deep dive](./concept6_explanation.md)
---

# Experiment with Different Inputs

Modify `myblob.yaml`.

### Experiment 1

```yaml
size: medium
```

Expected

```text
Standard_GRS
```

---

### Experiment 2

```yaml
size: large
```

Expected

```text
Premium_LRS
```

---

### Experiment 3

```yaml
environment: prod
```

Expected

```text
production
```

Namespace

```text
demo-storage-prod
```

---

### Experiment 4

```yaml
storageName: photos
```

Expected Namespace

```text
photos-prod
```

Expected Endpoint

```text
https://photos.blob.core.windows.net
```

---

# Useful Debugging Commands

```bash
kubectl get xblobstorage

kubectl describe xblobstorage my-storage

kubectl get object

kubectl describe object <object-name>

kubectl get ns

kubectl get configmap -A

kubectl get secret -A

kubectl logs -n crossplane-system deploy/provider-kubernetes

kubectl logs -n crossplane-system deploy/crossplane
```

---

# Learning Outcomes

After completing this module, you should understand:

* How to **patch** values from a Composite Resource into managed resources.
* How to use **map transforms** to translate user input into provider-specific values.
* How to apply **multiple transforms** within the same composition.
* How to use **combine patches** to derive new values from multiple inputs.
* How to expose application-ready information through **connection secrets**.

These concepts are fundamental to building reusable platform APIs with Crossplane and are directly applicable when moving from this local Kubernetes lab to real cloud providers such as Azure, AWS, or GCP.
