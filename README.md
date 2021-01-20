# Overview

The `gke-metrics-helm` project is a collections of useful tools for performing common operations on a Kubernetes cluster (the specific examples use GKE (Google Kubernetes Engine)).

# What's in the project?

The project includes:

* [script to backup kubernetes configuration files](backup/k8s-config-dump-to-yaml.sh)
* [deployment of kubernetes applications using Helm package manager](deploy)
* [creation of custom Kubernetes metric (GKE)](metrics)
* [demo of Sidecar design pattern](metrics)
* [script to provision a Kubernetes cluster in Google Cloud Platform environment](provision/gke-cluster-create.sh)