[Crossplane](https://www.crossplane.io/?utm_source=chatgpt.com) is an open-source framework that turns a Kubernetes cluster into a **universal control plane**. Instead of using separate tools to manage cloud infrastructure, databases, Kubernetes clusters, and applications, you define everything declaratively using Kubernetes APIs, and Crossplane continuously reconciles the actual state to match the desired state. ([crossplane.io][1])

### A simple way to think about it

* **Terraform** answers: *"How do I create these cloud resources?"*
* **Kubernetes** answers: *"How do I keep my containers running?"*
* **Crossplane** answers: *"How do I build a platform where developers can safely provision infrastructure and applications through simple APIs?"*

For example, instead of every developer needing to know how to configure:

* an AWS VPC
* subnets
* an RDS database
* IAM roles
* Kubernetes namespaces

you expose a single custom resource like:

```yaml
apiVersion: platform.example.com/v1
kind: Database
metadata:
  name: customer-db
spec:
  size: small
  region: us-east-1
```

Crossplane then creates and manages all the underlying AWS resources automatically.

### How it works

Crossplane has a few key concepts:

1. **Providers**

   * Connect Crossplane to external systems.
   * Examples: AWS, Azure, GCP, Kubernetes, GitHub, Helm.

2. **Managed Resources**

   * Represent individual cloud resources.
   * Example:

     * AWS RDS instance
     * S3 bucket
     * VPC

3. **Compositions**

   * Combine multiple managed resources into a reusable higher-level abstraction.
   * Example:

     * "Production Database" creates:

       * VPC
       * Security Group
       * RDS
       * Backup policy

4. **Composite Resources (XRs)**

   * The custom APIs your developers consume.
   * They hide infrastructure complexity.

### Example

Without Crossplane:

```
Developer
   │
Terraform
   │
AWS
```

With Crossplane:

```
Developer
      │
kubectl apply Database.yaml
      │
Crossplane
      │
Creates:
  ├── VPC
  ├── Subnets
  ├── RDS
  ├── IAM
  └── Secrets
```

The developer only interacts with the `Database` resource.

### Why organizations use Crossplane

* Self-service infrastructure for developers
* Standardized cloud resource configurations
* Multi-cloud support (AWS, Azure, GCP, etc.)
* GitOps-friendly workflows with tools like Argo CD or Flux
* Continuous reconciliation (it automatically corrects configuration drift)
* Policy and security built into platform APIs rather than individual scripts. ([docs.crossplane.io][2])

### Crossplane vs. Terraform

| Feature                      | Crossplane | Terraform          |
| ---------------------------- | ---------- | ------------------ |
| Declarative                  | ✅          | ✅                  |
| Continuous reconciliation    | ✅          | ❌ (runs on demand) |
| Kubernetes-native            | ✅          | Limited            |
| Build reusable platform APIs | ✅          | Limited            |
| GitOps integration           | Excellent  | Good               |
| Multi-cloud                  | ✅          | ✅                  |

Many organizations actually **use them together**. Crossplane focuses on building a Kubernetes-native platform and self-service APIs, while Terraform can still be used where it makes sense.

### Who should use it?

Crossplane is particularly valuable for:

* Platform engineering teams
* Organizations running Kubernetes
* Companies building internal developer platforms (IDPs)
* Teams managing infrastructure across multiple cloud providers
* Enterprises that want developers to provision infrastructure through simple, standardized APIs rather than cloud-specific tooling. ([crossplane.io][1])

If you're familiar with Kubernetes, you can think of Crossplane as **"Kubernetes for cloud infrastructure"**—it extends Kubernetes' declarative model beyond containers to manage databases, networks, storage, cloud services, and even SaaS resources.

[1]: https://www.crossplane.io/?utm_source=chatgpt.com "Crossplane Is the Cloud-Native Framework for Platform ..."
[2]: https://docs.crossplane.io/latest/whats-crossplane/?utm_source=chatgpt.com "What's Crossplane? · Crossplane v2.2"
