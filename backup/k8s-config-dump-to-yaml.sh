#!/bin/bash

###################################################################
#Script Name	  :k8s-config-dump-to-yaml.sh
#Description	  :Script that reads and dumps the YAML configuration files
#                for all resources in all namespaces in a Kubernetes cluster
#Args           :
#Author         :Damian McDonald
#License        :GPL
#Version        :1.0.0
#Maintainer     :Damian McDonald
#Status         :Development
###################################################################

set -e

NAMESPACES=$(kubectl get ns -o jsonpath="{.items[*].metadata.name}")
RESOURCES=$(kubectl api-resources --namespaced -o name | tr "\n" " ")

for ns in ${NAMESPACES};do
  for resource in ${RESOURCES};do
    echo "Retrieving reources for namespace ${ns}"
    rsrcs=$(kubectl -n ${ns} get -o json ${resource}|jq '.items[].metadata.name'|sed "s/\"//g")
    for r in ${rsrcs};do
      dir="k8s-yaml/${ns}/${resource}"
      mkdir -p "${dir}"
      echo "Retrieving yaml for resource: ${resource} in namespace: ${ns}"
      kubectl -n ${ns} get -o yaml ${resource} ${r} > "${dir}/${r}.yaml"
    done
  done
done