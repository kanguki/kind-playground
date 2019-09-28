# Playground k8s cluster 
The following instructions will help you to create a local k8s cluster into your local machine using [kind](https://kind.sigs.k8s.io)

Before to start you need to install the following CLI: `kind`, `kubectl`, and `helm`.

The cluster will includes the following base components:
- coredns (installed by default by kind)
- nginx ingress
- k8s dashboard

## Create the cluster using Kind
The following command will create the playground k8S cluster with one master and 3 worker nodes.
```
kind create cluster --name playground --config ./kind.config
```

After creating a cluster, you can use `kubectl` to interact with it by using the configuration file generated by kind:
```
export KUBECONFIG="$(kind get kubeconfig-path)"
kubectl cluster-info
```

## Initialize Helm 
`Tiller` is the server component for `helm`. `Tiller` will be present in the kubernetes cluster and the `helm` CLI talks to it for deploying applications using `helm charts`.
`Helm` will be managing your cluster resources. So we need to add necessary permissions to the `tiller` components which will reside in the cluster `kube-system` namespace.

We need to:
- create a `service account` named `tiller`
- create a `ClusterRoleBinding` with cluster-admin permissions to the `tiller service account`

You start creating these resources using `kubectl`
```
kubectl apply -f ./helm/helm-rbac.yaml
```

Then you initialize `helm`. Doing so, a deployment named `tiller-deploy` will be deployed in the `kube-system` namespace.

Initialize `helm` using the following command.
```
helm init --service-account=tiller --history-max 300
```

You can check the tiller deployment in the `kube-system` namespace using `kubectl`.
```
kubectl get deployment tiller-deploy -n kube-system
```

## Deploy Nginx Ingress using Helm
Execute the following helm install command to deploy an `nginx ingress` in the playgorund cluster inside the `nginx` namespace. 
```
helm install stable/nginx-ingress --name nginx-ingress --namespace nginx --set rbac.create=true
```

## Deploy Kubernetes Dashboard using Helm
Execute the following helm install command to deploy an `kubertenes dashboard` in the playgorund cluster inside the `kube-public` namespace.

`kube-public` namespace is usally reserved for cluster usage, in case that some resources should be visible and readable publicly throughout the whole cluster. 

```
helm install stable/kubernetes-dashboard --name dashbaord --namespace kube-public
```