#!/bin/bash

type kind >/dev/null    2>&1 || { echo >&2 "kind    is required but it's not installed."; exit 1; }
type helm >/dev/null    2>&1 || { echo >&2 "helm    is required but it's not installed."; exit 1; }
type kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is required but it's not installed."; exit 1; }

{ kind get clusters | grep -q playground; } && { echo "Playground cluster is already created."; exit 1; }

### KIND
echo ">>> Creating PLAYGROUND cluster"
kind create cluster --name playground --config ./kind.config

export KUBECONFIG="$(kind get kubeconfig-path --name="playground")"
watch kubectl get nodes -o wide

### HELM
echo ">>> Deploying HELM."
kubectl apply -f ./helm/helm-rbac.yaml
helm init --service-account=tiller --history-max 300

kubectl rollout status deployment tiller-deploy -n kube-system

helm repo add bitnami https://charts.bitnami.com/bitnami
helm update

### NGNIX
echo ">>> Deploying NGINIX."
helm install bitnami/nginx-ingress-controller --name ingress --namespace ingress \
-f ./nginx/nginx-values.yaml

kubectl rollout status deployment ingress-nginx-ingress-controller-default-backend -n ingress
kubectl rollout status deployment ingress-nginx-ingress-controller -n ingress

### HELLO-KUBE
kubectl apply -f ./hello-kube/hello-kube.yaml
kubectl rollout status deployment hello-kube 

### DASHBOARD
echo ">>> Deploying DASHBOARD."
helm install stable/kubernetes-dashboard --name dashboard --namespace kube-system

kubectl rollout status deployment dashboard-kubernetes-dashboard -n kube-system

TOKEN=$(kubectl -n kube-system describe secret tiller| awk '$1=="token:"{print $2}')
kubectl config set-credentials kubernetes-admin --token=${TOKEN}

### VIEW THE DASHBOARD
echo ">>> Accessing the DASHBOARD."
echo ""
echo "exec the following command:"
echo "   kubectl -n kube-system port-forward svc/dashboard-kubernetes-dashboard 8000:443"
echo "then use the the following URL in your favorite borwser"
echo "   https://localhost:8000"

echo "DONE."
