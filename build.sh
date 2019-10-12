#!/bin/bash

kind create cluster --name playground --config ./kind.config

export KUBECONFIG="$(kind get kubeconfig-path --name="playground")"

watch kubectl get nodes -o wide

kubectl apply -f ./helm/helm-rbac.yaml
helm init --service-account=tiller --history-max 300

watch kubectl -n kube-system get deployment tiller-deploy 

helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

helm install bitnami/nginx-ingress-controller --name ingress --namespace ingress \
-f ./nginx/nginx-values.yaml

watch kubectl -n ingress get deployment 

helm install stable/kubernetes-dashboard --name dashboard --namespace kube-system
TOKEN=$(kubectl -n kube-system describe secret tiller| awk '$1=="token:"{print $2}')
kubectl config set-credentials kubernetes-admin --token=${TOKEN}

watch kubectl -n kube-system get deployment dashboard-kubernetes-dashboard

echo "Open your favorite browser at https://localhost:8000"

kubectl -n kube-system port-forward svc/dashboard-kubernetes-dashboard 8000:443

echo "DONE."
