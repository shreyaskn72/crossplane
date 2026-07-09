I think **Module 3** is where Crossplane becomes much more interesting. Modules 1 and 2 were about **how to build a Composition**. Module 3 is about **how to manage Compositions at scale**.

Since your goal is to eventually understand Azure and real platform engineering, I'd suggest building Module 3 incrementally, just as we did for Module 2.

---

# Module 3 Overview

## Learning Objectives

By the end of Module 3, you'll understand:

```
                +-------------------+
                |   XBlobStorage    |
                +-------------------+
                         |
         selects Composition Revision
                         |
         +---------------+---------------+
         |                               |
+----------------------+        +----------------------+
| Composition v1       |        | Composition v2       |
| Standard_LRS         |        | Standard_ZRS         |
| endpoint v1          |        | endpoint v2          |
+----------------------+        +----------------------+
         ^
         |
Automatic / Manual Update Policies
```

---

# Module 3 Topics

We'll implement these in order:

```
Module 3

1. Nested Compositions
2. Composition Revisions
3. Composition Update Policies
```

This order makes the learning much easier.

---

# Lab Philosophy

We'll **reuse everything from Module 2**.

No Azure.

No new providers.

We'll continue using

* Namespace
* ConfigMap
* Secret

because we already understand those resources.

Now we'll focus entirely on **Composition lifecycle management**.

---

# Concept 1 — Nested Compositions

## What problem does it solve?

Suppose every application needs storage.

Today your Composition looks like

```
XBlobStorage
     │
     ├── Namespace
     ├── ConfigMap
     └── Secret
```

Now imagine every application also needs

* Database
* Queue
* Monitoring
* Cache
* Network Policy

Soon the Composition becomes enormous.

```
XApplication

 ├── Namespace
 ├── Storage
 ├── Database
 ├── Queue
 ├── Cache
 ├── Monitoring
 ├── Secrets
 ├── Network
 ├── DNS
 ├── Certificates
 └── ...
```

500+ lines.

Impossible to maintain.

---

## Nested Composition

Instead:

```
Application

        │
        ▼

+----------------------+
| XApplication         |
+----------------------+

        │

  creates

        │

        ▼

+----------------------+
| XBlobStorage         |
+----------------------+

        │

        ▼

Namespace
ConfigMap
Secret
```

Large platforms are built this way.

---

# Our Lab

We'll create

```
XApplication

↓

XBlobStorage

↓

Namespace
ConfigMap
Secret
```

This is exactly how real platform teams organize Crossplane.

---

# Concept 2 — Composition Revisions

This is probably the coolest feature in Crossplane.

Imagine today your platform creates

```
sku:
Standard_LRS
```

Tomorrow management decides

```
Everything should become

Standard_ZRS
```

Do you edit the Composition?

No.

Crossplane automatically creates

```
Composition Revision 1

↓

Composition Revision 2
```

Existing resources can stay on Revision 1.

New resources can use Revision 2.

---

Example

```
Revision 1

sku:

Standard_LRS
```

Revision 2

```
sku:

Standard_ZRS
```

Both exist simultaneously.

---

# Concept 3 — Update Policies

Suppose

```
Revision 1

↓

Standard_LRS
```

Later

```
Revision 2

↓

Standard_ZRS
```

Should existing Storage Accounts change?

Maybe.

Maybe not.

Crossplane lets you decide.

```
Automatic

or

Manual
```

Automatic

```
Revision 1

↓

Revision 2

↓

All Composite Resources update automatically
```

Manual

```
Revision 1

↓

Revision 2

↓

Existing resources remain unchanged
```

until you explicitly update them.

---

# Suggested Lab Structure

We'll create **three labs**.

---

## Lab 1

Nested Composition

```
XApplication

↓

XBlobStorage

↓

Namespace
ConfigMap
Secret
```

You'll learn

* Composition inside another Composition
* Platform modularity
* Reuse

---

## Lab 2

Composition Revisions

We'll modify

```
Standard_LRS
```

to

```
Standard_ZRS
```

Observe

```
kubectl get compositionrevisions
```

and see multiple revisions created automatically.

---

## Lab 3

Composition Update Policies

We'll switch between

```
Automatic
```

and

```
Manual
```

and observe

```
kubectl describe xblobstorage
```

to see which revision is in use.

---

# Deliverables

By the end of Module 3, you'll have:

```
Module 3/

├── Lab 1
│     Nested Compositions
│
├── Lab 2
│     Composition Revisions
│
├── Lab 3
│     Update Policies
│
├── Developer Runbook
│
└── QA Runbook
```

just like we created for Module 2.

---

