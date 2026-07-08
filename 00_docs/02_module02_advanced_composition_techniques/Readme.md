Since you've successfully completed **Module 1**, let's build **Module 2** on top of your existing lab rather than creating a completely new one.

Your current Module 1 architecture is:

```text
XBlobStorage
      |
      v
Composition
      |
      +---- Namespace
      +---- ConfigMap
      +---- Secret
```

For **Module 2**, we'll extend it to demonstrate the five most important Crossplane features used in real enterprise platform APIs:

```text
Patching
Transforms
Combine patches
Readiness checks
Connection secrets
```

I'll skip **EnvironmentConfigs** for now because Crossplane v2 changed that story considerably and it's easier to understand after mastering the other concepts.

---

# Module 2 Architecture

We'll evolve your API from:

```yaml
apiVersion: platform.demo/v1alpha1
kind: XBlobStorage

spec:
  location: eastus
  storageName: demo-storage
```

to:

```yaml
apiVersion: platform.demo/v1alpha1
kind: XBlobStorage

metadata:
  name: photos

spec:
  storageName: photos
  location: eastus
  environment: dev
  size: small
```

---

# Concept 1 — Patching

You already did simple patching:

```yaml
patches:
- fromFieldPath: spec.storageName
  toFieldPath: spec.forProvider.manifest.metadata.name
```

Let's extend this.

Add to your XRD:

```yaml
properties:

  storageName:
    type: string

  location:
    type: string

  environment:
    type: string

  size:
    type: string
```

---

# Concept 2 — Transforms

Suppose developers specify:

```yaml
size: small
```

but your platform wants:

```text
small -> Standard_LRS
large -> Premium_LRS
```

Add to ConfigMap:

```yaml
data:
  sku: placeholder
```

Patch:

```yaml
patches:
- fromFieldPath: spec.size
  toFieldPath: spec.forProvider.manifest.data.sku

  transforms:
  - type: map

    map:
      small: Standard_LRS
      medium: Standard_GRS
      large: Premium_LRS
```

Now:

```yaml
size: small
```

becomes:

```yaml
sku: Standard_LRS
```

---

# Concept 3 — Transform Environment

Developer:

```yaml
environment: dev
```

Platform:

```text
dev  -> development
prod -> production
```

Example:

```yaml
patches:
- fromFieldPath: spec.environment
  toFieldPath: spec.forProvider.manifest.data.environment

  transforms:
  - type: map

    map:
      dev: development
      prod: production
```

---

# Concept 4 — Combine Patches

Suppose you want:

```text
photos-dev
```

generated automatically.

Add:

```yaml
metadata:
  name: placeholder
```

Then:

```yaml
patches:

- type: CombineFromComposite

  combine:

    variables:

    - fromFieldPath: spec.storageName

    - fromFieldPath: spec.environment

    strategy: string

    string:
      fmt: "%s-%s"

  toFieldPath: spec.forProvider.manifest.metadata.name
```

Input:

```yaml
storageName: photos
environment: dev
```

Output:

```text
photos-dev
```

---

# Concept 5 — Readiness Checks

Currently Crossplane waits for provider readiness.

You can customize this:

```yaml
readinessChecks:

- type: MatchString
  fieldPath: status.atProvider.manifest.kind
  matchString: ConfigMap
```

or:

```yaml
readinessChecks:

- type: NonEmpty
  fieldPath: status.atProvider.manifest
```

This is heavily used in Azure:

```text
ResourceGroup READY
       ↓
StorageAccount READY
       ↓
BlobContainer READY
```

---

# Concept 6 — Connection Secrets

In Azure:

```text
Storage Account
       ↓
Connection String
       ↓
Kubernetes Secret
```

We can simulate that.

Add to Secret:

```yaml
stringData:

  accountName: placeholder

  endpoint: placeholder
```

Patch:

```yaml
patches:

- fromFieldPath: spec.storageName
  toFieldPath: spec.forProvider.manifest.stringData.accountName
```

And:

```yaml
patches:

- type: CombineFromComposite

  combine:
    variables:
    - fromFieldPath: spec.storageName

    strategy: string

    string:
      fmt: "https://%s.blob.core.windows.net"

  toFieldPath: spec.forProvider.manifest.stringData.endpoint
```

Result:

```yaml
apiVersion: v1
kind: Secret

stringData:
  accountName: photos
  endpoint: https://photos.blob.core.windows.net
```

---

# Final Module 2 Example

Developer creates:

```yaml
apiVersion: platform.demo/v1alpha1
kind: XBlobStorage

metadata:
  name: photos

spec:
  storageName: photos
  location: eastus
  size: small
  environment: dev
```

Crossplane creates:

```text
Namespace:
    photos-dev

ConfigMap:
    sku=Standard_LRS
    environment=development

Secret:
    accountName=photos
    endpoint=https://photos.blob.core.windows.net
```

---

# Skills learned in Module 2

| Concept           | Example                      |
| ----------------- | ---------------------------- |
| Patch             | `storageName -> namespace`   |
| Transform         | `small -> Standard_LRS`      |
| Combine           | `photos + dev -> photos-dev` |
| Readiness         | Wait for resource creation   |
| Connection Secret | Generate connection details  |

---


I think this is the perfect next lab because it teaches the exact features used in real enterprise Azure Crossplane APIs. 🚀