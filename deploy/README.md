# HELM on GKE

This guide will walk you through installing, configuring and using HELM on GKE.

* [Prerequisites](#prerequisites)
	* [kubectl installation](##kubectl-installation)
	* [Authorize kubectl for GKE cluster](##authorize-kubectl-for-gke-cluster)
* [Helm installation](#helm-installation)
	* [Getting Helm](##getting-helm)
	* [Initialize Helm, add chart repository and perform a test install](##initialize-helm,-add-chart-repository-and-perform-a-test-install)
* [Creating a Helm chart](#creating-a-helm-chart)
* [Installing the Helm Charts](#installing-the-helm-charts)
* [Useful Helm commands](#useful-helm-commands)

# Prerequisites

Before getting started with Helm, we need to ensure that the GCE (or Cloud Shell) instance you will use has `kubectl` installed and configured with a GCP Service Account that has GKE Cluster Admin permissions.

## kubectl installation

The commands below can be used to install `kubectl` on an Ubuntu 18.04 LTS Operating System.

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update

sudo apt-get install -y kubectl

kubectl version
```

## Authorize kubectl for GKE cluster

The commands below can be used to authorize `kubectl` for GKE cluster access.

```bash
# Global variables
export GCP_ZONE="europe-west4-b"
export CLUSTER_NAME="test-cluster"
CLUSTER_USER="some.user@some.domain.com"

# Step 1 is to ensure that the GCP Service Account used by the GCE instance (or Cloud Shell) has GKE Cluster Admin permissions. If you already know that the service account associated with the GCP instance has GKE Cluster Admin permissions then you can skip this step.
gcloud auth login ${CLUSTER_USER}

# Create GKE credentials and set cluster context
gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${GCP_ZONE}

# run a test to make sure that kubectl is authorized to connect to the GKE cluster
kubectl get nodes
```

# Helm installation

These next steps will take you through obtaining Helm, installing Helm and testing that Helm is working.

## Getting Helm

There are many ways to [install helm](https://helm.sh/docs/intro/install/). In this guide we will use the *script* installation method.

```bash
# download the helm installation script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3

# set the executable bit on the helm script
chmod 700 get_helm.sh

# execute the helm script
sudo ./get_helm.sh

# verify that helm has been installed correctly
helm version
```

## Initialize Helm, add chart repository and perform a test install

The commands below will initilize Helm, add a chart repository, perform a test install and then cleanup (delete) the test install.

```bash
# initialize helm by adding the official Google stable charts repo
helm repo add stable https://charts.helm.sh/stable

# search the charts to show that helm is initialized and working correctly
helm search repo stable

# update the helm charts
helm repo update

# install a memcached instance to GKE so we can test if helm install is working
helm install stable/memcached --generate-name

# if we have a successful helm install, let's forward the local port to the memcached deployment so we can do a quick test
export POD_NAME=$(helm ls --short | grep memcached)

kubectl port-forward ${POD_NAME}-0 11211 &

# with the local port forarded, let's try to set a key on memcached.
# if we see STORED, then everything has worked correctly
echo -e 'set mykey 0 60 5\r\nhello\r' | nc localhost 11211

# we can also check the GKE deployments to make sure that the install has worked correctly. The command below should show us some instances on a memcached pod.
kubectl get pods

# delete the memcached install to cleanup our test
export MEMCACHED_DEPLOY=$(helm ls --short | grep memcached)
helm delete ${MEMCACHED_DEPLOY}

# run a final helm ls command to make sure that memcached has been deleted
helm ls
```

# Creating a Helm chart

Helm acts as a package manager for Kubernetes and the packaging format of helm is Charts. 

Explaining all the details regarding Helm chart creation is beyond the scope of the readme file. 

With that said, a good starting point is to use the [helm create](https://helm.sh/docs/helm/helm_create/) to generate a chart-skeleton which can be used as a base for you custom chart configuration. 

Below is an example of the `helm create` command.

```bash
# create a chart template
export CHART_NAME=face-reco
helm create ${CHART_NAME}

# navigate to the chart template and view the directory structure
cd ${CHART_NAME}

# use command to view the chart strcuture
# the chart directory structure appears as shown below
# ├── Chart.yaml
# ├── charts
# ├── templates
# │   ├── NOTES.txt
# │   ├── _helpers.tpl
# │   ├── deployment.yaml
# │   ├── hpa.yaml
# │   ├── ingress.yaml
# │   ├── service.yaml
# │   ├── serviceaccount.yaml
# │   └── tests
# │       └── test-connection.yaml
# └── values.yaml

# best option is to use tree but it is not always installed on all linux distros
# sudo apt install tree -y && tree

# if you don't want to install tree, below is a poor man's alternative using native linux commands
find . | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
```

For convenience, an example of the `helm create` template can be found at [skeleton-chart](skeleton-chart) and can be copied as the basis for future Helm chart creation.

Additionally, take a look at the concrete custom charts that are available in in the [charts](charts) directory.

# Installing the Helm Charts

Installing the Helm Charts can be performed via the [install.sh](install.sh) script.

The [install.sh](install.sh)  does the following:
1. creates a new kubernetes `namespace` - this is where the Helm charts will be installed
2. creates a new kubernetes `clusterrolebinding` - this is required in order to deploy the custom-metrics server
3. installs the custom-metrics server
4. installs the NVIDIA GPU drivers and plugins
5. installs the [app-deps](charts/app-deps) Helm Chart - this is the first Helm chart that must be deployed as it installs dependencies which are required by all the other Helm charts
6. installs the [api](charts/api) Helm Chart

A simplified version of the [install.sh](install.sh) script is presented below.

```bash
#!/bin/bash

# declare global script variables
K8S_NAMESPACE="dev-poc"
CLUSTER_USER="some.user@some.domain.com"
CUSTOM_METRICS_ADAPTER="https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml"
NVIDIA_DRIVER_PLUGIN_MANIFEST="manifests/nvidia-driver-plugin-install.yaml"

# create the new kubernetes namespace
kubectl create namespace ${K8S_NAMESPACE}

# create a clusterrole binding, required in order to deploy the custom metrics server
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin --user ${CLUSTER_USER}

# add the custom metrics server
kubectl apply -f ${CUSTOM_METRICS_ADAPTER}

# install the nvidia gpu drivers and plugins
kubectl apply -f ${NVIDIA_DRIVER_PLUGIN_MANIFEST}

# helm install the application dependencies - this must be the first helm chart installed
helm install ./app-deps --generate-name --namespace=${K8S_NAMESPACE}

# helm install the api-reco chart
helm install ./api --generate-name --namespace=${K8S_NAMESPACE}
```

# Useful Helm commands

Below is a selection of useful Helm commands.

| Command  | Description  | Example |
|---|---|---|
| [helm create](https://helm.sh/docs/helm/helm_create/) | Create a skelton template for a Helm Chart | `helm create my-chart` |
| [helm repo](https://helm.sh/docs/helm/helm_repo/) | Add, list, remove, update, and index chart repositories | `helm repo add stable https://charts.helm.sh/stable` |
| [helm search](https://helm.sh/docs/helm/helm_search/) | Search for a keyword in charts | `helm search repo stable` |
| [helm install](https://helm.sh/docs/helm/helm_install/) | Installs a Helm chart | `helm install ./chart-dir --generate-name --namespace=k8s-namespace` |
| [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) | Uninstalls a Helm chart | `helm uninstall chart-name --namespace=k8s-namespace` |