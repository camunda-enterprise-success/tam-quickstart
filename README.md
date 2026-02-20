# Camunda 8 Local - TAM Specific

> [!NOTE]
>
> This is an unofficial fork of [camunda-platform-local](https://github.com/camunda/camunda-platform-local)

> [!CAUTION]
>
> This GitHub repository is mainly for `debugging` **NOT** `testing`! If you want to test the Camunda Helm chart, please use our [GitHub Actions Workflow for Helm chart](https://github.com/camunda/camunda-platform-helm/blob/main/docs/gha-workflows.md). The GHA workflow is much closer the production setup.

Local setup for Camunda 8 with Ingress and TLS!

This repo aims to reduce the time and effort spent to spin up the Camunda 8 locally by automating the setup
it should work the same way across operating systems (Linux, MacOS, and Windows).

# Why?

One of the recurring challenges for different teams (e.g., support and dev) was testing a bug fix
or reproducing an issue when the Ingress controllers and TLS are enabled because that involves extra steps
for DNS and certificate configuration (the expected way our clients use the Camunda 8).

# How does it work?

The domain `local.distro.ultrawombat.com` and all its sub-domains point to `127.0.0.1`,
and it will work with the Kubernetes local cluster that exposes ports `80` and `443` locally (configured via `KinD`).

---

# Prerequisites

The following tools are required:

- Make (For [Windows](https://earthly.dev/blog/makefiles-on-windows/))
- [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Helm](https://helm.sh/docs/intro/install/)

# How to use

- Clone/download this repo
- Navigate to camunda-platform-local-main folder within repo
- Run `make help` to learn about available commands