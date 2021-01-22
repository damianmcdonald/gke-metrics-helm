# Contents

* [Overview](#overview)
* [Build and push Docker image to GCP Container Registry](#build-and-push-docker-image-to-gcp-container-registry)
* [Make a local test](#make-a-local-test)
* [Deploy the solution to GKE for testing](#deploy-the-solution-to-gke-for-testing)

# Overview

This mini project includes a docker image that can be used for WebSocket connectivity testing.

In addition, the mini-project provides instructions for deploying this WebSocket Docker image as a LoadBalanced GKE deployment.

Credit for the Docker image goes to *ksdn117*:

* https://hub.docker.com/r/ksdn117/web-socket-test
* https://github.com/sashimi3/web-socket-test

The Docker image has been modified slightly from ksdn117's original for this project, see [Dockerfile](Dockerfile).

Working instructions can be found in the following article:
* https://medium.com/johnjjung/how-to-use-gcp-loadbalancer-with-websockets-on-kubernetes-using-services-ingresses-and-backend-16a5565e4702

# Build and push Docker image to GCP Container Registry

The steps below assume that *Docker is installed* on the machine that this script will be executed on.

```bash
# enable GCP Container Registry
gcloud services enable containerregistry.googleapis.com

# add GCP Cloud Registry as a Docker creds helper 
gcloud auth configure-docker "eu.gcr.io"

# build and tag the Docker image
docker build -t eu.gcr.io/<GCP_PROJECT_ID>/web-socket-test:1.0.0 .

# push the tagged image from local registry to GCP Cloud Registry
docker push eu.gcr.io/<GCP_PROJECT_ID>/web-socket-test:1.0.0
```

# Make a local test

The commands below will allow you to make a local test of the websocket Docker image. This assumes that the Docker image has already been built.

```bash
# install the websocket node libs
sudo apt install node-ws

# execute the docker image in the background
docker run -p 8010:8010 -d --name web-socket-test eu.gcr.io/<GCP_PROJECT_ID>/web-socket-test:1.0.0

# make a web socket connection and start sending messages
wscat --connect ws://$(CONTAINER_HOST_IP_ADDRESS):8010

# e.g.
# connected (press CTRL+C to quit)
# > Hello world

# < Client message: hola on pod: web-socket-example-6ccf6f895d-z2mjg
# >
```

# Deploy the solution to GKE for testing

`web-socket-test` has been packaged as a Helm chart to permit simple deployment to GKE.

The commands below can be used to deploy the Helm chart. It is assumed that Helm is already installed on the machine that you will run these commands from. 

If you need more information regarding Helm, please see the deploy [README](deploy/README.md) file.

```bash
# navigate to the gke-deployment-scripts/deploy folder within the source code
cd gke-deployment-scripts/deploy

# deploy the helm chart intot he default namespace
helm install ./websockets-example --generate-name --namespace=default

# check the successful deployment of k8s resources - you are looking for web-socket-* resources
kubectl get deployments
kubectl get pods # expect to see X web-socket-example pods
kubectl get svc # expect to see a LoadBalancer with an external IP
kubectl get backendconfig

# wait for the LoadBalancer external IP to assigned
bash -c 'external_ip=""; while [ -z $external_ip ]; do echo "Waiting for Load Balancer external IP to be assigned..."; external_ip=$(kubectl get svc web-socket-lb --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}"); [ -z "$external_ip" ] && sleep 10; done; echo "End point ready-" && echo $external_ip'

# now that you have the LoadBalancer external IP assigned, you can execute a test

# NOTE: even though the LoadBalancer has an external IP and it seems to be functioning, it is very normal that you have to wait 5-10 minutes AFTER the assignement of the LoadBalancer external IP before everything works correctly.

# If you recieve a message such as;
#   error: Error: connect ECONNREFUSED 34.91.52.101:8080
# This means that the LoadBalancer needs more time. Go grab a coffee!!

# make a web socket connection and start sending messages
wscat --connect ws://$(LOAD_BALANCER_EXTERNAL_IP):8010

# e.g.
# connected (press CTRL+C to quit)
# > Hello world

# < Client message: hola on pod: web-socket-example-6ccf6f895d-z2mjg
# >
```