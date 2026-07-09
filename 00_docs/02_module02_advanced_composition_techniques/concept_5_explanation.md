**Readiness Checks** are one of the most misunderstood Crossplane features, so let's first understand *why* they exist before implementing them.
"In Pipeline Compositions (Crossplane v2), readiness is generally managed by the composition function and the managed resource controllers. The legacy readinessChecks field does not apply to the function-patch-and-transform resource definitions."
---

# Why do we need Readiness Checks?

Imagine provisioning Azure resources:

```text
Resource Group
      │
      ▼
Storage Account
      │
      ▼
Blob Container
```

The Blob Container **cannot** be created until the Storage Account is actually ready.

Crossplane needs a way to determine:

> "Is this composed resource ready yet?"

By default, Crossplane asks the provider. But you can override that behavior using `readinessChecks`.

---

# Our Local Lab

In your lab, we have:

```text
Namespace
      │
      ▼
ConfigMap
      │
      ▼
Secret
```

All three are created almost instantly, so readiness checks aren't strictly necessary—but they are still useful to learn.

---

# Readiness Check Types

The most common ones are:

| Type             | Purpose                                               |
| ---------------- | ----------------------------------------------------- |
| `None`           | Don't wait at all                                     |
| `NonEmpty`       | Field must exist and not be empty                     |
| `MatchString`    | Field must equal a specific value                     |
| `MatchInteger`   | Field must equal a specific integer                   |
| `MatchCondition` | Match a Kubernetes condition (used by many providers) |

---

# We'll use `NonEmpty`

We'll tell Crossplane:

> "This ConfigMap is ready only after its metadata UID has been assigned."

Every Kubernetes object gets a UID after creation, so this is a good readiness signal.

---

# Modify your ConfigMap resource

Inside the `storageaccount` resource, after `patches`, add:

```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: metadata.uid
```

So it becomes:

```yaml
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
            sku: placeholder
            environment: placeholder

  patches:
    ...
    ...

  readinessChecks:
    - type: NonEmpty
      fieldPath: metadata.uid
```

---

# Namespace

You can also add the same readiness check:

```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: metadata.uid
```

---

# Secret

Likewise:

```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: metadata.uid
```

---

# What does this do?

Crossplane now waits until the created Kubernetes object has a populated `metadata.uid` before considering that composed resource ready.

The flow becomes:

```text
Create ConfigMap
        │
        ▼
metadata.uid exists?
        │
   Yes ─────────► READY
```

---

# Verify It

Apply your updated composition:

```bash
kubectl apply -f composition.yaml
```

Recreate your composite resource if needed:

```bash
kubectl delete xblobstorage my-storage
kubectl apply -f myblob.yaml
```

Then inspect the composite:

```bash
kubectl describe xblobstorage my-storage
```

You should eventually see events similar to:

```text
Composed resource "namespace" is ready
Composed resource "storageaccount" is ready
Composed resource "container" is ready
```

And:

```bash
kubectl get xblobstorage
```

should show:

```text
NAME         SYNCED   READY
my-storage   True     True
```

---

# Is `metadata.uid` realistic?

For our Kubernetes-based lab, it's a convenient and reliable field.

In real cloud providers, readiness checks typically use provider status fields. For example:

Azure Storage Account:

```yaml
readinessChecks:
  - type: MatchCondition
    fieldPath: status.conditions[?(@.type=="Ready")].status
    matchString: "True"
```

or

```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: status.atProvider.id
```

because the cloud provider populates those fields only after the resource is fully provisioned.

---

## Recommendation

For **Module 2**, use the following readiness check on all three composed resources:

```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: metadata.uid
```

It's simple, demonstrates the feature clearly, and closely mirrors the pattern you'll use later with Azure providers—except there you'll check provider-specific status fields instead of Kubernetes metadata.
