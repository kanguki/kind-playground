#!/bin/bash

export KUBECONFIG

### HELP
help() {    
cat <<END
>>> Accessing the DASHBOARD.

1) set your cluster config

    export KUBECONFIG=$(kind get kubeconfig-path --name=playground)

2) create a port forward to the dashboard service

    kubectl -n kube-system port-forward svc/dashboard-kubernetes-dashboard 8443:443

3) use the the following URL in your favorite browser

    https://localhost:8443
END
}

require () {
    type kind >/dev/null    2>&1 || { echo >&2 "kind    is required but it's not installed."; exit 1; }
    type helm >/dev/null    2>&1 || { echo >&2 "helm    is required but it's not installed."; exit 1; }
    type kubectl >/dev/null 2>&1 || { echo >&2 "kubectl is required but it's not installed."; exit 1; }
}

check() {
    { kind get clusters | grep -q playground; } && { echo "Playground cluster is already created."; help; exit 1; }
}

### KIND
create_cluster() {
    echo ">>> Creating PLAYGROUND cluster"
    kind create cluster --name playground --config ./kind.config

    KUBECONFIG="$(kind get kubeconfig-path --name="playground")"
    watch kubectl get nodes -o wide
}

### HELM
deploy_helm() {
    echo ">>> Deploying HELM."
    kubectl apply -f ./helm/helm-rbac.yaml
    helm init --service-account=tiller --history-max 300

    kubectl rollout status deployment tiller-deploy -n kube-system

    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm update
}

### NGNIX
deploy_ngnix() {
    echo ">>> Deploying NGINIX."
    helm install bitnami/nginx-ingress-controller --name ingress --namespace ingress \
    -f ./nginx/nginx-values.yaml

    kubectl rollout status deployment ingress-nginx-ingress-controller-default-backend -n ingress
    kubectl rollout status deployment ingress-nginx-ingress-controller -n ingress
}

### HELLO-KUBE
deploy_hellokube() {
    kubectl apply -f ./hello-kube/hello-kube.yaml
    kubectl rollout status deployment hello-kube 
}

### DASHBOARD
deploy_dashboard() {
    echo ">>> Deploying DASHBOARD."
    helm install stable/kubernetes-dashboard --name dashboard --namespace kube-system

    kubectl rollout status deployment dashboard-kubernetes-dashboard -n kube-system

    TOKEN=$(kubectl -n kube-system describe secret tiller| awk '$1=="token:"{print $2}')
    kubectl config set-credentials kubernetes-admin --token="${TOKEN}"
}

main() {
    require
    check   
    create_cluster
    deploy_helm
    deploy_ngnix
    deploy_hellokube
    deploy_dashboard
    help
}

main
