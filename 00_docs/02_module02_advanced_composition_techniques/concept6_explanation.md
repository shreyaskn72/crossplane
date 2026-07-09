This is actually one of the **most useful Crossplane concepts** because almost every cloud resource produces connection details.

In Azure:

```text
Storage Account
        │
        ▼
Primary Access Key
Connection String
Blob Endpoint
Account Name
```

Crossplane automatically writes these into a Kubernetes Secret.

---

# Our Local Lab

Since we're not talking to Azure, we'll **simulate** this behavior.

Instead of Azure returning:

```text
AccountName=photos
Endpoint=https://photos.blob.core.windows.net
AccessKey=abc123...
```

our platform will generate a Secret containing:

```yaml
apiVersion: v1
kind: Secret

stringData:
  accountName: demo-storage
  endpoint: https://demo-storage.blob.core.windows.net
  environment: development
```

This demonstrates the exact same concept.

---

# What is a Connection Secret?

Think of it like this:

```text
Developer
      │
      ▼
Storage Account
      │
      ▼
Connection Details
      │
      ▼
Kubernetes Secret
      │
      ▼
Application
```

The application never needs to know how the storage account was created—it simply reads the Secret.

---

# Our Lab

We already have a Secret:

```yaml
kind: Secret

stringData:
  container: images
  environment: placeholder
```

We'll enhance it to represent a real connection secret.

---

# Step 1

Modify the Secret's `stringData`.

Replace:

```yaml
stringData:
  container: images
  environment: placeholder
```

with:

```yaml
stringData:
  accountName: placeholder
  endpoint: placeholder
  environment: placeholder
```

---

# Step 2

Patch the account name.

Add:

```yaml
- fromFieldPath: spec.storageName
  toFieldPath: spec.forProvider.manifest.stringData.accountName
```

Now:

```yaml
storageName: demo-storage
```

becomes

```yaml
accountName: demo-storage
```

---

# Step 3

Generate the endpoint automatically.

This is another **Combine Patch**.

Add:

```yaml
- type: CombineFromComposite

  combine:

    variables:
      - fromFieldPath: spec.storageName

    strategy: string

    string:
      fmt: "https://%s.blob.core.windows.net"

  toFieldPath: spec.forProvider.manifest.stringData.endpoint
```

Suppose

```yaml
storageName: photos
```

Crossplane generates

```text
https://photos.blob.core.windows.net
```

---

# Step 4

Keep the environment transform.

```yaml
- fromFieldPath: spec.environment
  toFieldPath: spec.forProvider.manifest.stringData.environment

  transforms:
    - type: map
      map:
        dev: development
        prod: production
```

---

# Final Secret Resource

Your Secret should now look like this:

```yaml
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
            accountName: placeholder
            endpoint: placeholder
            environment: placeholder

  patches:

  - fromFieldPath: spec.storageName
    toFieldPath: spec.forProvider.manifest.stringData.accountName

  - fromFieldPath: spec.environment
    toFieldPath: spec.forProvider.manifest.stringData.environment

    transforms:
      - type: map
        map:
          dev: development
          prod: production

  - type: CombineFromComposite

    combine:
      variables:
        - fromFieldPath: spec.storageName
        - fromFieldPath: spec.environment

      strategy: string

      string:
        fmt: "%s-%s"

    toFieldPath: spec.forProvider.manifest.metadata.namespace

  - type: CombineFromComposite

    combine:
      variables:
        - fromFieldPath: spec.storageName

      strategy: string

      string:
        fmt: "https://%s.blob.core.windows.net"

    toFieldPath: spec.forProvider.manifest.stringData.endpoint
```

---

# Apply

```bash
kubectl apply -f composition.yaml
kubectl delete xblobstorage my-storage
kubectl apply -f myblob.yaml
```

---

# Verify

List the Secret:

```bash
kubectl get secret -n demo-storage-dev
```

Expected:

```text
blob-container
```

View the Secret:

```bash
kubectl get secret blob-container \
  -n demo-storage-dev \
  -o yaml
```

Kubernetes stores Secret values under `data` as Base64. Decode them to verify:

```bash
kubectl get secret blob-container \
  -n demo-storage-dev \
  -o jsonpath='{.data.accountName}' | base64 --decode
```

Expected:

```text
demo-storage
```

---

```bash
kubectl get secret blob-container \
  -n demo-storage-dev \
  -o jsonpath='{.data.endpoint}' | base64 --decode
```

Expected:

```text
https://demo-storage.blob.core.windows.net
```

---

```bash
kubectl get secret blob-container \
  -n demo-storage-dev \
  -o jsonpath='{.data.environment}' | base64 --decode
```

Expected:

```text
development
```

---

# What you've learned

This lab now closely mirrors what happens with real cloud providers:

1. **Patch** → Copy `storageName` into `accountName`.
2. **Transform** → Convert `dev` into `development`.
3. **Combine** → Build a provider-specific endpoint URL from the storage account name.
4. **Connection Secret** → Store application-ready connection information in a Kubernetes Secret.

When you later switch from the Kubernetes provider to the Azure provider, the same concept applies. The difference is that Azure will generate real values such as the storage account endpoint and access keys, and Crossplane will publish them as connection details rather than your composition constructing simulated values. This makes the transition from your local lab to a real Azure environment very natural.
