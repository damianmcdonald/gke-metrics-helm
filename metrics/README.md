# Pod with Sidecar

The `Pod with Sidecar` mini-project provides the following functionality:
* Create a custom GCP Monitoring metric in the `custom.googleapis.com` namespace
* Deploy a Kubernetes pod with a sidecar that can gather and push metrics to the custom metric
* Delete the custom GCP Monitoring metric

# Getting the project

Clone the git project: 

`git clone https://github.com/damianmcdonald/gke-metrics-helm.git gke-metrics-helm`

Navigate to the the Pod with Sidecar projcet: 

`cd gke-metrics-helm/metrics`

# Create a custom GCP Monitoring metric

The first step in creating a custom GCP Monitoring metric is to install the prerequisite software and create a python virtual environment.

```bash
# install python virtualenv
sudo apt install -y python3-venv python3-pip

# create a virtual env for the project
python3 -m venv pod-with-sidecar

# activate the virtual env
source pod-with-sidecar/bin/activate

# install the python dependencies into the virtual env
python3 -m pip install wheel
python3 -m pip install -r requirements.txt
```

Create the custom metric via the command below:

`python3 custom_metric.py CREATE project_id metric_descriptor metric_description`

A concrete example:

`python3 custom_metric.py CREATE my-gcp-project 'sidecar_avg_inf_time' 'Average inference time metric'`

After the metric has been created successfully, you can deactivate the virtual environment.

```bash
# deactivate the virtual env
deactivate
```

# Build the Pod with Sidecar project

The `Pod with Sidecar` project is based on 2 containers:
* Primary container: [primary-app](primary-app)
* Sidecar container: [sidecar](sidecar)

Both containers are based on Docker image which must be built and pushed to GCP Container Registry.

```bash
# configure your gcloud command with a user with permissions to push images to Cloud Registry
gcloud auth login user@gcp-account.com

# add GCP Cloud Registry as a Docker creds helper 
gcloud auth configure-docker "eu.gcr.io"

# build the primary-app image
cd primary-app

# build and tag the Docker image
docker build -t eu.gcr.io/<GCP_PROJECT_ID>/primary-app:1.0.0 .

# push the tagged image from local registry to GCP Cloud Registry
docker push eu.gcr.io/<GCP_PROJECT_ID>/primary-app:1.0.0

# build the sidecar image
cd ..
cd sidecar

# build and tag the Docker image
docker build -t eu.gcr.io/<GCP_PROJECT_ID>/sidecar:1.0.0 .

# push the tagged image from local registry to GCP Cloud Registry
docker push eu.gcr.io/<GCP_PROJECT_ID>/sidecar:1.0.0
```

# Deploy the Pod with Sidecar

* Create a Service account with the name `pod-with-sidecar-sa`
* Assign the role: `monitoring.metricWriter`
* Create a JSON key and download it

The `Pod with Sidecar` project can be deployed with the following `kubectl` commands.

```bash
# gcloud container clusters get-credentials ${CLUSTER_NAME} --zone ${GCP_ZONE}
gcloud container clusters get-credentials test-cluster --zone europe-west4-b

# add the Service Account as a Kubernetes secret by refering to the json key you downloaded earlier
kubectl create secret generic sidecar-key --from-file=key.json=PATH-TO-KEY-FILE.json

# apply the sidecar pod
kubectl apply -f pod-with-sidecar.yaml

######################################################################
#
# Alternate approach with GKE Pod Workload Identity
# Provided for information only
#
######################################################################

# enable workload identity on the cluster
# https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
# gcloud container clusters update CLUSTER_NAME --workload-pool=PROJECT_ID.svc.id.goog --zone ZONE
# gcloud container clusters update test-cluster --workload-pool=my-gcp-project.svc.id.goog --zone europe-west4-b

# add the Config Connector to the cluster node pools
# https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall
# gcloud container node-pools update NODE_POOL --workload-metadata=GKE_METADATA --cluster CLUSTER_NAME --zone ZONE
# gcloud container node-pools update default-pool --workload-metadata=GKE_METADATA --cluster test-cluster --zone europe-west4-b
# gcloud container node-pools update gpu-pool --workload-metadata=GKE_METADATA --cluster test-cluster --zone europe-west4-b

# enable the Config Connector on the cluster
# gcloud container clusters update CLUSTER_NAME --update-addons ConfigConnector=ENABLED --zone ZONE
# gcloud container clusters update test-cluster --update-addons ConfigConnector=ENABLED --zone europe-west4-b

# create the service account that gives the sidecar container permissions to wite to cloud monitoring
# https://cloud.google.com/kubernetes-engine/docs/tutorials/authenticating-to-cloud-platform
# https://cloud.google.com/monitoring/access-control
# kubectl apply -f pod-with-sidecar-service-account.yaml
```


# Delete the custom GCP Monitoring metric

Once you are finished testing the `Pod with Sidecar` project, you can delete the custom GCP Monitoring metric.

Delete the custom metric via the command below:

`python3 custom_metric.py DELETE project_id metric_descriptor`

A concrete example:

```bash
# activate the virtual env
source pod-with-sidecar/bin/activate

# delete the custom metric
python3 custom_metric.py DELETE my-gcp-project 'sidecar_avg_inf_time'
```

You will also need to manually delete any other resources created:
* Service Account: `pod-with-sidecar-sa`
* Container Registry images:
    * eu.gcr.io/my-gcp-project/primary-app:1.0.0
    * eu.gcr.io/my-gcp-project/sidecar:1.0.0
* GKE cluster (if you were using an ephemeral cluster)
* the local `pod-with-sidecar` git project