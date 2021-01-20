#!/bin/bash

###################################################################
#Script Name	  :install.sh
#Description	  :Install script that installs:
#                  * custom admin role (required to install custom metrics server)
#                  * custom metrics server
#                  * nvidia gpu drivers and plugins
#                  * apps-deps helm chart (application dependencies required by all other helm charts)
#                  * api helm chart
#Args           :
#Author         :Damian McDonald
#Credits        :Damian McDonald
#License        :GPL
#Version        :1.0.0
#Maintainer     :Damian McDonald
#Status         :Development
###################################################################

# define console colours
RED='\033[0;31m'
BLACK='\033[0;30m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# declare global script variables
K8S_NAMESPACE="dev-poc"
CLUSTER_USER="some.user@some.domain.com"
CUSTOM_METRICS_ADAPTER="https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml"
NVIDIA_DRIVER_PLUGIN_MANIFEST="manifests/nvidia-driver-plugin-install.yaml"

# create the new kubernetes namespace
echo -e "Creating kubernetes namespace: ${GREEN}${K8S_NAMESPACE}${NC}"
kubectl create namespace ${K8S_NAMESPACE}

# create a clusterrole binding, required in order to deploy the custom metrics server
echo ""
echo -e "Creating clusterrolebinding for user: ${BLUE}${CLUSTER_USER}${NC}"
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole cluster-admin --user ${CLUSTER_USER}

# add the custom metrics server
echo ""
echo -e "Installing the ${PURPLE}custom metrics server${NC}"
kubectl apply -f ${CUSTOM_METRICS_ADAPTER}

# install the nvidia gpu drivers and plugins
echo ""
echo -e "Installing the ${CYAN}NVIDIA GPU drivers and plugins${NC}"
kubectl apply -f ${NVIDIA_DRIVER_PLUGIN_MANIFEST}

# helm install the application dependencies - this must be the first helm chart installed
echo ""
echo -e "Installing Helm Chart for ${YELLOW}app-deps${NC}"
helm install ./charts/app-deps --generate-name --namespace=${K8S_NAMESPACE}

# helm install the api-reco chart
echo ""
echo -e "Installing Helm Chart for ${YELLOW}api${NC}"
helm install ./charts/api --generate-name --namespace=${K8S_NAMESPACE}