PYTHON ?= python3
MAKEFLAGS += --no-print-directory
CLUSTER_CONFIG := clusters/kind/kind-cluster-config.yaml
CLUSTER_NAME ?= $(shell awk '/^name: /{print $$2}' $(CLUSTER_CONFIG))
HELM_COMMAND_ACTION ?= install
CAMUNDA_CHART_VERSION_LATEST ?= 0.0.0-snapshot-latest
CAMUNDA_CHART_VERSION_ALPHA ?= 0.0.0-snapshot-alpha

help-banner:
	@{ \
	echo "     ####################################################"; \
	echo "     ##                                                ##"; \
	echo "     ##     ##     ## ######## ##       ########       ##"; \
	echo "     ##     ##     ## ##       ##       ##     ##      ##"; \
	echo "     ##     ##     ## ##       ##       ##     ##      ##"; \
	echo "     ##     ######### ######   ##       ########       ##"; \
	echo "     ##     ##     ## ##       ##       ##             ##"; \
	echo "     ##     ##     ## ##       ##       ##             ##"; \
	echo "     ##     ##     ## ######## ######## ##             ##"; \
	echo "     ##                                                ##"; \
	echo "     ####################################################"; \
	echo ""; \
	echo ""; \
	}
	
help: help-banner
	@{ \
	echo "Available Commands"; \
	echo "------------------"; \
	echo "camunda.custom.install - Used to install kind cluster, Camunda 8.x, and monitoring stack. "; \
	echo "     Optional Parameter - VERSION - Specify helm chart version (e.g. VERSION=12.7.6)"; \
	echo "                          Default value: Latest Stable Version"; \
	echo "     Optional Parameter - CLUSTER_NAME - Specify cluster name prefix (e.g. CLUSTER_NAME=camunda-8-8)"; \
	echo "                          Default value: camunda-platform-local"; \
	echo "     https://helm.camunda.io/camunda-platform/version-matrix/"; \
	echo ""; \
	echo "upgrade-custom - used to Upgrade Camunda. "; \
	echo "     Optional Parameter - VERSION - Specify helm chart version (e.g. VERSION=12.7.6)"; \
	echo "     https://helm.camunda.io/camunda-platform/version-matrix/"; \
	echo ""; \
	echo "clean-custom - Used to completely uninstall camunda-custom-install cluster by deleting the Kind cluster"; \
	echo ""; \
	echo "get-url - Get the local URL used to access the cluster."; \
	echo ""; \
	echo "open-ports - Port-forward necessary ports for Prometheus (9090) and Grafana (8080)."; \
	echo ""; \
	echo "grafana-creds - Get default credentials to access Grafana"; \
	echo ""; \
	echo ""; \
	}
	
	
hosts-add:
	$(PYTHON) modules/cert/hosts_update.py --ip "127.0.0.1" --host "camunda.es.local"

hosts-remove:
	$(PYTHON) modules/cert/hosts_update.py --ip "$(HOST_IP)" --host "camunda.es.local" --remove
	
	
check-vars:
	@echo "VERSION: $(VERSION)"
	@echo "NAME: $(CLUSTER_NAME)"

generate-ca-cert:
	mkcert -install
	mkcert -cert-file ./modules/cert/tls.crt -key-file ./modules/cert/tls.key *.camunda.es.local 

generate-secret-yaml: generate-ca-cert
	kubectl create secret tls camunda-tls \
		--cert=./modules/cert/tls.crt \
		--key=./modules/cert/tls.key \
		-n camunda-platform \
		--dry-run=client -o yaml > ./modules/camunda-platform/secret.yaml

camunda.custom.install.infra:
ifndef VERSION
	@echo "Latest Stable Version"
else
	@echo "Installing version: $(VERSION)"
endif
	@echo "Generating certs..."
	@$(MAKE) generate-secret-yaml 
	@echo "Create Cluster..."
	kind create cluster --name $(CLUSTER_NAME) --config .\clusters\kind\kind-cluster-config.yaml
	@echo "Adjust for Local setup..."
	kubectl cluster-info --context kind-$(CLUSTER_NAME)
	kubectl kustomize --enable-helm clusters/kind | kubectl apply -f -
	kubectl delete pod -n kube-system -l k8s-app=kube-dns
	@echo "Install Monitoring..."
	helm install prometheus prometheus-community/kube-prometheus-stack --create-namespace -n camunda-platform -f ./prometheus-operator-values.yml --set prometheusOperator.tlsProxy.enabled=false

camunda.custom.install: camunda.custom.install.infra
ifndef VERSION
	@echo "Install Latest Stable Version..."
	@$(MAKE) camunda.setup.latestStable
else
	@echo "Install Version $(VERSION)..."
	@$(MAKE) camunda.setup.specificVersion
endif
	
	
grafana-creds:
	@echo "Grafana Creds: "
	@echo "User: $$(kubectl get secret grafana-admin-password -n camunda-platform -o jsonpath='{.data.admin-user}' | base64 -d)"
	@echo "Password: $$(kubectl get secret grafana-admin-password -n camunda-platform -o jsonpath='{.data.admin-password}' | base64 -d)"

clean-custom:
	kind delete cluster --name $(CLUSTER_NAME)
	
upgrade-custom:
ifndef VERSION
	@echo "Upgrade to Latest Stable Version..."
	helm upgrade camunda camunda/camunda-platform \
		--create-namespace --namespace camunda-platform \
		--values deployments/common/values-camunda-platform.yaml \
		--values deployments/common/values-camunda-platform-custom.yaml \
		--values deployments/camunda-platform-latest/values-camunda-platform-extra.yaml
else
	@echo "Upgrade to Version $(VERSION)..."
	helm upgrade camunda camunda/camunda-platform \
		--create-namespace --namespace camunda-platform --version $(VERSION) \
		--values deployments/common/values-camunda-platform.yaml \
		--values deployments/common/values-camunda-platform-custom.yaml \
		--values deployments/camunda-platform-latest/values-camunda-platform-extra.yaml
endif

get-url:
	@echo "URL: $$(kubectl get ingress -A | awk '/http|platform/{print "http://"$$4}')"
	
open-ports:
	@echo "Starting port forwards..."
	@nohup kubectl port-forward svc/prometheus-grafana 8080:80 -n camunda-platform > /tmp/grafana-pf.log 2>&1 &
	@echo "Grafana listening on port 8080"
	@nohup kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n camunda-platform > /tmp/prometheus-pf.log 2>&1 &
	@echo "Prometheus listening on port 9090"
	@echo "Port forwards started."
	@echo ""
	@$(MAKE) grafana-creds
	@echo ""
	@$(MAKE) get-url
	
	
.asdf.plugins-add:
	#
	# Add plugins from .tool-versions file within the repo.
	# If the plugin is already installed asdf exits with 2, so grep is used to handle that.
	for plugin in $$(awk '{print $$1}' .tool-versions); do \
		asdf plugin add $${plugin} 2>&1 | (grep "already added" && exit 0); \
	done

tools.install: .asdf.plugins-add
	asdf install

cluster.init:
	kind create cluster --config $(CLUSTER_CONFIG)

cluster.clean:
	kind delete cluster --name $(CLUSTER_NAME)

infra.init:
	kubectl kustomize --enable-helm clusters/kind | kubectl apply -f -
	kubectl delete pod -n kube-system -l k8s-app=kube-dns

camunda.init:
	kubectl apply -k modules/camunda-platform

camunda.registrySecret:
	kubectl create secret docker-registry registry-camunda-cloud \
			--namespace camunda-platform \
			--docker-server "registry.camunda.cloud" \
			--docker-username "$${TEST_DOCKER_USERNAME_CAMUNDA_CLOUD}" \
			--docker-password "$${TEST_DOCKER_PASSWORD_CAMUNDA_CLOUD}"

camunda.helmRepo:
	helm repo add camunda https://helm.camunda.io
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update

camunda.setup.latestStable: camunda.helmRepo camunda.init
	helm $(HELM_COMMAND_ACTION) camunda camunda/camunda-platform \
		--create-namespace --namespace camunda-platform \
		--values deployments/common/values-camunda-platform.yaml \
		--values deployments/common/values-camunda-platform-custom.yaml \
		--values deployments/camunda-platform-latest/values-camunda-platform-extra.yaml

camunda.setup.latestSnapshot: camunda.init
	helm $(HELM_COMMAND_ACTION) camunda oci://ghcr.io/camunda/helm/camunda-platform \
		--version $(CAMUNDA_CHART_VERSION_LATEST) \
		--create-namespace --namespace camunda-platform \
		--values deployments/common/values-camunda-platform.yaml \
		--values deployments/common/values-camunda-platform-custom.yaml \
		--values deployments/camunda-platform-latest/values-camunda-platform-extra.yaml
		
camunda.setup.specificVersion: camunda.init
	@echo "Installing version $(VERSION) of Camunda"
	helm $(HELM_COMMAND_ACTION) camunda camunda/camunda-platform \
		--version $(VERSION) \
		--create-namespace --namespace camunda-platform \
		--values deployments/common/values-camunda-platform.yaml \
		--values deployments/common/values-camunda-platform-custom.yaml \
		--values deployments/camunda-platform-latest/values-camunda-platform-extra.yaml

camunda.setup.alphaSnapshot: camunda.init
	helm $(HELM_COMMAND_ACTION) camunda oci://ghcr.io/camunda/helm/camunda-platform \
		--version $(CAMUNDA_CHART_VERSION_ALPHA) \
		--create-namespace --namespace camunda-platform \
		--values deployments/common/values-camunda-platform.yaml \
		--values deployments/common/values-camunda-platform-custom.yaml \
		--values deployments/camunda-platform-alpha/values-camunda-platform-extra.yaml

camunda.clean:
	kubectl delete ns camunda-platform

shell-check:
	@echo SHELL is: $(SHELL)

#
# Shorthand.
#

pre:
	$(MAKE) tools.install

init:
	$(MAKE) cluster.init
	$(MAKE) infra.init
	$(MAKE) camunda.init

clean:
	$(MAKE) cluster.clean
