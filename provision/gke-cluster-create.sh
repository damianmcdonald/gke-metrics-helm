#!/bin/bash

###################################################################
#Script Name	  :gke-cluster-create.sh
#Description	  :Provisioning script which creates a GKE cluster with 2 node pools, one of which has GPUs
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

# creates a GKE zonal cluster with a default initial non-GPU node pool for the Central API pods
# https://cloud.google.com/sdk/gcloud/reference/container/clusters/create
# https://cloud.google.com/kubernetes-engine/docs/reference/rest/v1/projects.locations.clusters#Cluster.AddonsConfig
# default cluster config: gcloud container get-server-config

GKE_PROJECT=some-gcp-project
GKE_REGION=europe-west4
GKE_ZONE=europe-west4-b
GKE_NETWORK=somenetwork
GKE_SUBNET=subnet-test
GKE_PODS_SECONDARY_RANGE_NAME=subnet-test-pods
GKE_SERVICES_SECONDARY_RANGE_NAME=subnet-test-services
GKE_SUBNET_RANGE=10.10.0.0/24
GKE_PODS_ID_RANGE=10.20.0.0/14
GKE_SERVICES_IP_RANGE=10.30.0.0/20

#echo "Creating VPC for GKE ..."

#gcloud compute networks create $GKE_NETWORK --project=$GKE_PROJECT \
#--bgp-routing-mode=regional --subnet-mode=custom 

#echo "Creating subnet for GKE ..."

#gcloud compute networks subnets create $GKE_SUBNET --network=$GKE_NETWORK --region=$GKE_REGION \
#--range=$GKE_SUBNET_RANGE --enable-private-ip-google-access --purpose=PRIVATE \
#--secondary-range="$GKE_PODS_SECONDARY_RANGE_NAME=$GKE_PODS_ID_RANGE,$GKE_SERVICES_SECONDARY_RANGE_NAME=$GKE_SERVICES_IP_RANGE"

GKE_CLUSTER_NAME=test-cluster
GKE_CLUSTER_CHANNEL=stable
GKE_RESOURCE_USAGE_BIGQUERY_DATASET=gke_resources_usage_test
GKE_WORKLOAD_POOL="$GKE_PROJECT.svc.id.goog"
GKE_MASTER_AUTHORIZED_GKE_NETWORKS=10.100.0.0/24,
GKE_MASTER_IPV4_CIDR=172.16.1.0/28 

DEFAULT_NODE_POOL_MAX_NODES_PER_POOL=100
DEFAULT_NODE_POOL_MAX_PODS_PER_NODE=110
DEFAULT_NODE_POOL_NUM_NODES=1
DEFAULT_NODE_POOL_MIN_NODES=1
DEFAULT_NODE_POOL_MAX_NODES=2
DEFAULT_NODE_POOL_MACHINE_TYPE=n1-standard-1
DEFAULT_NODE_POOL_IMAGE_TYPE=COS
DEFAULT_NODE_POOL_SSD_COUNT_PER_NODE=1
DEFAULT_NODE_POOL_DISK_TYPE=pd-standard
DEFAULT_NODE_POOL_DISK_SIZE=100
DEFAULT_NODE_POOL_MAX_SURGE_UPGRADE=1
DEFAULT_NODE_POOL_MAX_NODES_UNAVAILABLE=0
DEFAULT_NODE_POOL_GKE_NETWORK_TAG=gke-cpu-network-default-tag
DEFAULT_NODE_POOL_LABEL=default-pool-node

echo -e "Creating cluster ${YELLOW}${GKE_CLUSTER_NAME}${NC} with a default node pool ..."

gcloud beta container --project $GKE_PROJECT clusters create $GKE_CLUSTER_NAME \
  --zone $GKE_ZONE --no-enable-basic-auth --release-channel=$GKE_CLUSTER_CHANNEL \
  --scopes "https://www.googleapis.com/auth/cloud-platform" --node-locations $GKE_ZONE  \
  --network $GKE_NETWORK  --subnetwork $GKE_SUBNET --enable-ip-alias --enable-stackdriver-kubernetes \
  --metadata disable-legacy-endpoints=true  --enable-private-nodes \
  --enable-master-authorized-networks --master-authorized-networks $GKE_MASTER_AUTHORIZED_GKE_NETWORKS \
  --master-ipv4-cidr $GKE_MASTER_IPV4_CIDR \
  --no-enable-basic-auth --no-issue-client-certificate  --no-enable-legacy-authorization\
  --workload-pool=$GKE_WORKLOAD_POOL\
  --cluster-secondary-range-name=$GKE_PODS_SECONDARY_RANGE_NAME \
  --services-secondary-range-name=$GKE_SERVICES_SECONDARY_RANGE_NAME \
  --resource-usage-bigquery-dataset $GKE_RESOURCE_USAGE_BIGQUERY_DATASET --enable-resource-consumption-metering \
  --enable-shielded-nodes --shielded-integrity-monitoring --shielded-secure-boot \
  --machine-type $DEFAULT_NODE_POOL_MACHINE_TYPE --image-type $DEFAULT_NODE_POOL_IMAGE_TYPE \
  --disk-type $DEFAULT_NODE_POOL_DISK_TYPE --disk-size $DEFAULT_NODE_POOL_DISK_SIZE \
  --local-ssd-count $DEFAULT_NODE_POOL_SSD_COUNT_PER_NODE  \
  --max-pods-per-node $DEFAULT_NODE_POOL_MAX_PODS_PER_NODE \
  --num-nodes $DEFAULT_NODE_POOL_NUM_NODES  \
  --enable-intra-node-visibility --default-max-pods-per-node $DEFAULT_NODE_POOL_MAX_PODS_PER_NODE \
  --enable-autoscaling --min-nodes $DEFAULT_NODE_POOL_MIN_NODES --max-nodes $DEFAULT_NODE_POOL_MAX_NODES \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing,NodeLocalDNS \
  --enable-autoupgrade --enable-autorepair --max-surge-upgrade $DEFAULT_NODE_POOL_MAX_SURGE_UPGRADE \
  --max-unavailable-upgrade $DEFAULT_NODE_POOL_MAX_NODES_UNAVAILABLE \
  --tags $DEFAULT_NODE_POOL_GKE_NETWORK_TAG --node-labels nodepool=$DEFAULT_NODE_POOL_LABEL  

# add a node pool with gpus
# https://cloud.google.com/sdk/gcloud/reference/container/node-pools/create
# https://cloud.google.com/kubernetes-engine/docs/how-to/gpus
# https://cloud.google.com/compute/docs/gpus/monitor-gpus#setup-script

GPU_NODE_POOL_NAME=gpu-pool
GPU_NODE_POOL_MACHINE_TYPE=custom-4-16384
GPU_NODE_POOL_IMAGE_TYPE=COS
GPU_TYPE=nvidia-tesla-t4
GPUS_PER_NODE=4
GPU_NODE_POOL_DISK_TYPE=pd-standard
GPU_NODE_POOL_DISK_SIZE=100
GPU_NODE_POOL_SSD_COUNT_PER_NODE=1
GPU_NODE_POOL_NUM_NODES=1
GPU_NODE_POOL_MIN_NODES=1
GPU_NODE_POOL_MAX_NODES=12
GPU_NODE_POOL_MAX_SURGE_UPGRADE=1
GPU_NODE_POOL_MAX_NODES_UNAVAILABLE=0
GPU_NODE_POOL_MAX_PODS_PER_NODE=110
GPU_NODE_POOL_GKE_NETWORK_TAG=gke-network-gpu-tag
GPU_NODE_POOL_LABEL=GPU-node

echo -e "Adding GPU Node Pool ${YELLOW}${GPU_NODE_POOL_NAME}${NC}, with ${YELLOW}${GPUS_PER_NODE} ${GPU_TYPE}${NC} GPUs per node."

gcloud beta container --project $GKE_PROJECT node-pools create $GPU_NODE_POOL_NAME \
  --cluster $GKE_CLUSTER_NAME --zone $GKE_ZONE  \
  --machine-type $GPU_NODE_POOL_MACHINE_TYPE  \
  --accelerator "type=$GPU_TYPE,count=$GPUS_PER_NODE" --image-type $GPU_NODE_POOL_IMAGE_TYPE \
  --disk-type $GPU_NODE_POOL_DISK_TYPE --disk-size $GPU_NODE_POOL_DISK_SIZE --local-ssd-count "1" \
  --metadata disable-legacy-endpoints=true --node-labels nodepool=$GPU_NODE_POOL_LABEL \
  --scopes "https://www.googleapis.com/auth/cloud-platform" --num-nodes $GPU_NODE_POOL_NUM_NODES \
  --enable-autoscaling --min-nodes $GPU_NODE_POOL_MIN_NODES --max-nodes $GPU_NODE_POOL_MAX_NODES \
  --enable-autoupgrade --enable-autorepair --max-surge-upgrade $GPU_NODE_POOL_MAX_SURGE_UPGRADE \
  --max-unavailable-upgrade $GPU_NODE_POOL_MAX_NODES_UNAVAILABLE \
  --max-pods-per-node $GPU_NODE_POOL_MAX_PODS_PER_NODE \
  --shielded-integrity-monitoring --shielded-secure-boot --tags $GPU_NODE_POOL_GKE_NETWORK_TAG \
  --node-labels=nvidia.com/gpu=present