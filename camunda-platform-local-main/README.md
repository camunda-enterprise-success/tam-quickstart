# Camunda 8 Local

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

If you use [asdf](https://asdf-vm.com/), you can install all the tools with the tested version in one shot:

```shell
make tools.install
```

---

# Setup

## Cluster

The Kubernetes cluster:

```shell
make cluster.init
```

## Infrastructure

The infra resources like Ingress:

```shell
make infra.init
```

## Secrets

### Web Modeler and Console

Camunda Web Modeler (<= 8.5) and Console are enterprise components that require access to the Camunda Docker registry.

```shell
# Set the password as a var (with a space before the command to avoid saving it in the shell history)
  export TEST_DOCKER_USERNAME_CAMUNDA_CLOUD='_REPLACE_WITH_YOUR_CAMUNDA_REGISTRY_USERNAME_'
  export TEST_DOCKER_PASSWORD_CAMUNDA_CLOUD='_REPLACE_WITH_YOUR_CAMUNDA_REGISTRY_PASSWORD_'

make camunda.registrySecret
```

## Camunda 8

The Helm values for Camunda Platform 8 could be customized
in [camunda-platform-latest/values-camunda-platform-extra.yaml](deployments/camunda-platform-latest/values-camunda-platform-extra.yaml)
or [camunda-platform-alpha/values-camunda-platform-extra.yaml](deployments/camunda-platform-alpha/values-camunda-platform-extra.yaml)

### Install the latest stable chart

```shell
make camunda.setup.latestStable
```

### Install the latest snapshot chart

```shell
make camunda.setup.latestSnapshot
```

### Install the alpha snapshot chart

```shell
make camunda.setup.alphaSnapshot
```

### Uninstall chart

```shell
make camunda.clean
```

# Cleanup

To delete the local Kubernetes cluster, please run:

```shell
make cluster.clean
```
---

# Access

- Console: https://local.distro.ultrawombat.com
- Keycloak: https://local.distro.ultrawombat.com/auth
- Identity: https://local.distro.ultrawombat.com/identity
- Web Modeler: https://local.distro.ultrawombat.com/modeler
- Operate: https://local.distro.ultrawombat.com/operate
- Tasklist: https://local.distro.ultrawombat.com/tasklist
- Optimize: https://local.distro.ultrawombat.com/optimize
- Zeebe (REST): https://local.distro.ultrawombat.com/zeebe
- Zeebe (gRPC): zeebe.local.distro.ultrawombat.com:443

## Deploy or execute a process from the Web Modeler

Communication between the Web Modeler backend, Zeebe, and Keycloak happens inside the Kubernetes cluster.
This means that in the deployment dialog, you have to enter the internal Kubernetes URL for Zeebe and Keycloak:
* Cluster endpoint: `http://camunda-zeebe-gateway:26500`
* OAuth URL: `http://camunda-keycloak:80/auth/realms/camunda-platform/protocol/openid-connect/token`

## Deploy or execute a process from the Desktop Modeler

Communication between Desktop Modeler, Zeebe, and Keycloak happens outside the Kubernetes cluster.
This means that in the deployment dialog, you have to enter the external URL for Zeebe and Keycloak:
* Cluster endpoint: `https://zeebe.local.distro.ultrawombat.com:443`
* OAuth URL: `https://local.distro.ultrawombat.com/auth/realms/camunda-platform/protocol/openid-connect/token`

# Configuring Service Startup

You have the ability to control which services start up by modifying the `values-camunda-platform-extra.yaml` file.
To disable a service from starting up, simply add the service name and set `enabled: false`.

## Launching only modeling dependencies

To launch only the modeling dependencies, such as the Web Modeler and Identity for process modeling, you have two options. You can either uncomment the preconfigured values file [values-camunda-platform-modeling-only.yaml](deployments/common/values-camunda-platform-modeling-only.yaml) or you can directly add the content to the `values-camunda-platform-extra.yaml` file.

# Pitfalls

## Fritz Box

The URls are working as the DNS entry for them resolves to `127.0.0.1`. If the FritzBox serves as DNS server, it will [refuse to resolve an entry to a private IP address](https://en.avm.de/service/knowledge-base/dok/FRITZ-Box-7360-int/663_No-DNS-resolution-of-private-IP-addresses/). This behavior can be changed by adding exceptions for `local.distro.ultrawombat.com`. Another option would be the selection of an alternative DNS server `1.1.1.1` for your device or [the FritzBox](https://avm.de/service/wissensdatenbank/dok/FRITZ-Box-7530/165_Andere-DNS-Server-in-FRITZ-Box-einrichten).

If none of this can be applied to your setup, you can modify your [hosts file](https://www.howtogeek.com/27350/beginner-geek-how-to-edit-your-hosts-file/) and add the following lines:
* `127.0.0.1 local.distro.ultrawombat.com`
* `127.0.0.1 zeebe.local.distro.ultrawombat.com`

## Mac
- Make sure you delegate enough CPU and memory to Docker. You can do this through the Docker UI.

Settings -> Resources</br>
CPU Limit = 12</br>
Memory Limit = 14GB
- Make sure that all tools are installed through asdf and not any other package manager such as brew. You can confirm if the tools are installed correctly through asdf by running the `which` command. For example:

```shell
which kubectl
/Users/<username>/.asdf/shims/kubectl
```

The tool should be located in the `.asdf` folder.

- When installing tools through the make file by running `make tools.install`, you might encounter this error:
```
# Add plugins from .tool-versions file within the repo.
# If the plugin is already installed asdf exits with 2, so grep is used to handle that.
for plugin in $(awk '{print $1}' .tool-versions); do \
		asdf plugin add ${plugin} 2>&1 | (grep "already added" && exit 0); \
	done
make: *** [.asdf.plugins-add] Error 1
```
Just run the same command again, which should work normally.

# Future plans

- Use one of Camunda's domains, like `local.camunda.com` or so, instead of the current one.
- Encrypt the domain certificate with Kustomize
  [SopsSecretGenerator](https://github.com/goabout/kustomize-sopssecretgenerator).

# DRI
The Distribution team.
For any questions, please use [#ask-distribution](https://camunda.slack.com/archives/C03UR0V2R2M).
