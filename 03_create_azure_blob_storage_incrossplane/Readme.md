To create an Azure Blob Storage account using Crossplane, you need to do four things:

1. Install Crossplane
2. Install the Azure provider
3. Configure Azure credentials
4. Create a Storage Account resource

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

## Step 2: Install the Azure provider

Crossplane supports Azure through providers.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-upjet-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure:v2.5.4
```

Apply it:

```bash
kubectl apply -f provider.yaml
```

Verify:

```bash
kubectl get providers
kubectl get pods -n crossplane-system
```

---

## Step 3: Configure Azure credentials

Create a service principal:

```bash
az ad sp create-for-rbac \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>
```

Example output:

```json
{
  "clientId": "xxxx",
  "clientSecret": "xxxx",
  "subscriptionId": "xxxx",
  "tenantId": "xxxx"
}
```

Create a credentials file:

```json
{
  "clientId": "xxxx",
  "clientSecret": "xxxx",
  "subscriptionId": "xxxx",
  "tenantId": "xxxx"
}
```

Create the Kubernetes secret:

```bash
kubectl create secret generic azure-secret \
    -n crossplane-system \
    --from-file=creds=azure-creds.json
```

Create a ProviderConfig:

```yaml
apiVersion: azure.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: creds
```

---

## Step 4: Create a Resource Group

Azure Storage Accounts must belong to a Resource Group.

```yaml
apiVersion: azure.upbound.io/v1beta1
kind: ResourceGroup
metadata:
  name: demo-rg
spec:
  forProvider:
    location: East US
  providerConfigRef:
    name: default
```

Apply:

```bash
kubectl apply -f resourcegroup.yaml
```

---

## Step 5: Create the Azure Storage Account

```yaml
apiVersion: storage.azure.upbound.io/v1beta1
kind: Account
metadata:
  name: mystorageaccount
spec:
  forProvider:
    accountTier: Standard
    accountReplicationType: LRS
    location: East US
    resourceGroupName: demo-rg

  providerConfigRef:
    name: default
```

Apply:

```bash
kubectl apply -f storageaccount.yaml
```

Check status:

```bash
kubectl get account.storage.azure.upbound.io
kubectl describe account.storage.azure.upbound.io mystorageaccount
```

---

## Step 6: Create a Blob Container

Once the storage account is ready:

```yaml
apiVersion: storage.azure.upbound.io/v1beta1
kind: Container
metadata:
  name: mycontainer
spec:
  forProvider:
    storageAccountName: mystorageaccount
    containerAccessType: private

  providerConfigRef:
    name: default
```

Apply:

```bash
kubectl apply -f container.yaml
```

---

## Complete hierarchy

```text
Crossplane
     |
     +-- ProviderConfig
     |
     +-- ResourceGroup
             |
             +-- StorageAccount
                      |
                      +-- BlobContainer
```

---

## Production approach (recommended)

In real organizations, developers usually do **not** create `ResourceGroup`, `Account`, and `Container` directly. Instead, platform engineers create a **Composition** such as:

```yaml
apiVersion: platform.company.io/v1
kind: BlobStorage
metadata:
  name: my-storage
spec:
  size: standard
  region: eastus
```

Crossplane then automatically creates:

* Resource Group
* Storage Account
* Blob Container
* Network rules
* Private endpoints
* RBAC assignments

This is the main value of Crossplane: **developers consume simple APIs while platform teams manage the cloud complexity underneath**.

---

Since wey don't have an Azure subscription, I can also show you how to **simulate Azure Blob Storage locally using Crossplane + Kind + provider-kubernetes**, which is a great way to learn Crossplane concepts without an Azure account.
