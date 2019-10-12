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
$ kind create cluster --name playground --config ./kind.config
```

After creating a cluster, you can use `kubectl` to interact with it by using the configuration file generated by kind:
```
$ export KUBECONFIG="$(kind get kubeconfig-path --name="playground")"
$ kubectl cluster-info
$ kubectl get nodes -o wide
$ kubectl get all --all-namespaces
```

## Initialize Helm 
`Tiller` is the server component for `helm`. `Tiller` will be present in the kubernetes cluster and the `helm` CLI talks to it for deploying applications using `helm charts`.
`Helm` will be managing your cluster resources. So we need to add necessary permissions to the `tiller` components which will reside in the cluster `kube-system` namespace.

We need to:
- create a `service account` named `tiller`
- create a `ClusterRoleBinding` with cluster-admin permissions to the `tiller service account`

You start creating these resources using `kubectl`
```
$ kubectl apply -f ./helm/helm-rbac.yaml
```

Then you initialize `helm`. Doing so, a deployment named `tiller-deploy` will be deployed in the `kube-system` namespace.

Initialize `helm` using the following command.
```
$ helm init --service-account=tiller --history-max 300
```

You can check the tiller deployment in the `kube-system` namespace using `kubectl`.
```
$ kubectl -n kube-system get deployment tiller-deploy 
```

## Adding Bitnami Helm Repository
Bitnami charts are carefully engineered, actively maintained and are the quickest and easiest way to deploy containers on a Kubernetes cluster.
```
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm update
```


## Deploy Nginx Ingress using Helm
Execute the following `helm install` command to deploy an `nginx ingress` in the playground cluster inside the `nginx` namespace. 
```
$ helm install bitnami/nginx-ingress-controller --name ingress --namespace ingress \
-f ./nginx/nginx-values.yaml
```

## Test ingress deploing the Hello-Kube using yaml (OPTIONAL)
Execute the following `kubectl apply` command to deploy `hello-kube` applications in the playground. Three instances of the application will be deployed.
```
$ kubectl apply -f ./hello-kube/hello-kube.yaml
```

After running `kubectl proxy`, use the following URL in your browser to access the `hello-kube` UI.
```
http://localhost:8001/api/v1/namespaces/default/services/hello-kube/proxy/
```

The following command will delete the `hello-kube` deployment.
```
$ kubectl delete -f ./hello-kube/hello-kube.yaml
```

## Deploy Kubernetes Dashboard using Helm 
Execute the following `helm install` command to deploy the `kubertenes dashboard` in the playground cluster inside the `kube-system` namespace.
```
$ helm install stable/kubernetes-dashboard --name dashboard --namespace kube-system
```

The `tiller` `service account` has cluster-admin permissions, so we add its token to the `${KUBECONFIG}` file. This allows to use the `${KUBECOFIG}` file to login in the `kubertenes dashboard`.
```
TOKEN=$(kubectl -n kube-system describe secret tiller| awk '$1=="token:"{print $2}')
kubectl config set-credentials kubernetes-admin --token=${TOKEN}
```

Use port forwarding to access the `kubertenes dashboard` service in the cluster.
```
kubectl -n kube-system port-forward svc/dashboard-kubernetes-dashboard 8000:443
```

Then open your favorite browser using the following URL
```
https://localhost:8000
```


