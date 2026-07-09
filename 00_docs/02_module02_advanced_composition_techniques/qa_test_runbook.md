Since this is a **learning lab**, I would write the runbook like a QA/Test Engineer guide rather than just a list of commands. The tester should understand **what feature is being validated**, **what commands to execute**, and **what the expected result is**.

---

# Module 2 Test Runbook

## Objective

This test validates that the Crossplane Composition correctly implements the following concepts:

| Concept              | Validation                                                                |
| -------------------- | ------------------------------------------------------------------------- |
| ✅ Patching           | Values from the composite resource are copied into composed resources.    |
| ✅ Map Transforms     | User-friendly values are transformed into platform-specific values.       |
| ✅ Combine Patches    | Multiple input fields are combined into one derived value.                |
| ✅ Connection Secrets | Connection information is automatically generated and stored in a Secret. |

---

# Test Environment

Before beginning, verify Crossplane is healthy.

```bash
kubectl get pods -n crossplane-system
```

Expected:

```
crossplane-xxxx                     Running
provider-kubernetes-xxxx            Running
function-patch-and-transform-xxxx   Running
```

Verify the provider:

```bash
kubectl get providers
```

Expected:

```
provider-kubernetes   True   True
```

Verify the ProviderConfig:

```bash
kubectl get providerconfig
```

Expected:

```
local
```

---

# Deploy the Platform

Apply the platform resources.

```bash
kubectl apply -f xrd.yaml

kubectl apply -f function.yaml

kubectl apply -f providerconfig.yaml

kubectl apply -f composition.yaml
```

Verify:

```bash
kubectl get xrd

kubectl get composition

kubectl get functions
```

Expected:

```
xblobstorages.platform.demo

blobstorage-local

function-patch-and-transform
```

---

# Create Storage

Deploy the composite resource.

```bash
kubectl apply -f myblob.yaml
```

Verify:

```bash
kubectl get xblobstorage
```

Expected:

```
NAME          SYNCED   READY
my-storage    True     True
```

---

# Test 1 — Patching

## Concept

The value

```
spec.storageName
```

should be patched into the Namespace name.

Input:

```yaml
storageName: demo-storage
environment: dev
```

Expected Namespace:

```
demo-storage-dev
```

Check:

```bash
kubectl get ns
```

Expected:

```
demo-storage-dev
```

PASS if Namespace exists.

---

# Test 2 — Transform (SKU)

## Concept

Developer provides

```yaml
size: small
```

Crossplane converts it to

```
Standard_LRS
```

Check ConfigMap

```bash
kubectl get configmap storage-account \
-n demo-storage-dev \
-o yaml
```

Expected

```yaml
data:
  sku: Standard_LRS
```

PASS if SKU equals Standard_LRS.

---

# Test 3 — Transform (Environment)

Developer input

```yaml
environment: dev
```

should become

```
development
```

Check

```bash
kubectl get configmap storage-account \
-n demo-storage-dev \
-o yaml
```

Expected

```yaml
data:
  environment: development
```

PASS if value equals development.

---

# Test 4 — Combine Patch

The namespace should be generated from

```
storageName
+

environment
```

Developer supplied

```
demo-storage

dev
```

Expected

```
demo-storage-dev
```

Verify Namespace

```bash
kubectl get ns
```

Expected

```
demo-storage-dev
```

Verify ConfigMap namespace

```bash
kubectl get configmap \
storage-account \
-n demo-storage-dev
```

Verify Secret namespace

```bash
kubectl get secret \
blob-container \
-n demo-storage-dev
```

PASS if all resources exist inside

```
demo-storage-dev
```

---

# Test 5 — Connection Secret

View Secret

```bash
kubectl get secret blob-container \
-n demo-storage-dev \
-o yaml
```

Decode account name

```bash
kubectl get secret blob-container \
-n demo-storage-dev \
-o jsonpath='{.data.accountName}' \
| base64 --decode
```

Expected

```
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

```
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

```
development
```

PASS if all values match.

---

# Test 6 — Validate Transform Mapping

Edit

```yaml
myblob.yaml
```

Replace

```yaml
size: small
environment: dev
```

with

```yaml
size: medium
environment: prod
```

Apply

```bash
kubectl apply -f myblob.yaml
```

Expected ConfigMap

```yaml
data:
  sku: Standard_GRS
  environment: production
```

Expected Namespace

```
demo-storage-prod
```

Expected Endpoint

```
https://demo-storage.blob.core.windows.net
```

Notice that only the namespace changes because it combines `storageName` and `environment`; the endpoint is based solely on `storageName`.

---

# Test 7 — Large Storage

Update

```yaml
size: large
```

Apply

```bash
kubectl apply -f myblob.yaml
```

Expected

```yaml
sku: Premium_LRS
```

PASS if transform is successful.

---

# Final Verification

Check all resources.

```bash
kubectl get xblobstorage

kubectl get object

kubectl get ns

kubectl get configmap -A

kubectl get secret -A
```

Expected

```
XBlobStorage
------------
READY=True

Namespace
---------
demo-storage-dev
(or demo-storage-prod)

ConfigMap
---------
storage-account

Secret
------
blob-container

Objects
-------
Namespace
ConfigMap
Secret
```

---

# Pass Criteria

| Test                  | Expected Result                                                                    |
| --------------------- | ---------------------------------------------------------------------------------- |
| Platform Deployment   | All platform resources installed successfully                                      |
| Composite Resource    | `READY=True`                                                                       |
| Patching              | Namespace derived from composite input                                             |
| SKU Transform         | `small → Standard_LRS`, `medium → Standard_GRS`, `large → Premium_LRS`             |
| Environment Transform | `dev → development`, `prod → production`                                           |
| Combine Patch         | Namespace follows `<storageName>-<environment>`                                    |
| Connection Secret     | Secret contains generated `accountName`, `endpoint`, and transformed `environment` |
| Managed Resources     | Namespace, ConfigMap, and Secret are all created successfully                      |

---

## Why this is a good QA runbook

This runbook doesn't just verify that resources exist—it verifies the **behavior** of each Crossplane feature independently. A tester can map each test directly to a Crossplane concept:

* **Patching** → Input fields are copied to composed resources.
* **Transforms** → User input is translated into platform-specific values.
* **Combine Patches** → Multiple fields are combined into a derived value.
* **Connection Secrets** → Platform-generated connection information is exposed to workloads.

This makes it easy to identify which concept has failed if a test does not produce the expected result.
