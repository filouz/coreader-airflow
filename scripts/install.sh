#!/bin/bash

NAMESPACE=$1
DEPLOYMENT_PATH=$2

if ! [ -x "$(command -v helm)" ]; then
    echo 'Helm is not installed. Installing now...' >&2
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo 'Helm is already installed.' >&2
fi

kubectl apply -f $DEPLOYMENT_PATH/namespace.yaml
kubectl apply -f $DEPLOYMENT_PATH/git-credentials.yaml

helm repo add apache-airflow https://airflow.apache.org

helm install -n $NAMESPACE airflow apache-airflow/airflow -f $DEPLOYMENT_PATH/airflow-values.yaml --debug