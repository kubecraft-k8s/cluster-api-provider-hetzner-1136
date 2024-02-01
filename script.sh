# https://cluster-api.sigs.k8s.io/clusterctl/overview#avoiding-github-rate-limiting
export GITHUB_TOKEN=""
export HCLOUD_SSH_KEY=""
export HCLOUD_TOKEN=""


export CLUSTER_NAME="demo"
export KUBECONFIG="$HOME/.kube/$CLUSTER_NAME-bootstrap"
export CONTROL_PLANE_MACHINE_COUNT=1
export WORKER_MACHINE_COUNT=1
export KUBERNETES_VERSION=1.29.1
export HCLOUD_REGION="nbg1"
export HCLOUD_CONTROL_PLANE_MACHINE_TYPE=cax11
export HCLOUD_WORKER_MACHINE_TYPE=cax11

function create_cluster {
  cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: "$CLUSTER_NAME-bootstrap"
nodes:
  - role: control-plane
    image: kindest/node:v1.29.0
EOF

  clusterctl init --core cluster-api --bootstrap kubeadm --control-plane kubeadm --infrastructure hetzner
  kubectl create secret generic hetzner --from-literal=hcloud=$HCLOUD_TOKEN
  kubectl patch secret hetzner -p '{"metadata":{"labels":{"clusterctl.cluster.x-k8s.io/move":""}}}'

  echo "Waiting for ClusterAPI deployments to be ready"
  kubectl wait --for=condition=Available deployment/caph-controller-manager -n caph-system
  kubectl wait --for=condition=Available deployment/capi-kubeadm-bootstrap-controller-manager -n capi-kubeadm-bootstrap-system
  kubectl wait --for=condition=Available deployment/capi-kubeadm-control-plane-controller-manager -n capi-kubeadm-control-plane-system
  kubectl wait --for=condition=Available deployment/capi-controller-manager -n capi-system
  clusterctl generate cluster $CLUSTER_NAME | kubectl apply -f-

  echo "Waiting for Cluster to be ready"
  kubectl wait --for=condition=Ready --timeout=10m "machinedeployment/$CLUSTER_NAME-md-0"
  clusterctl describe cluster "$CLUSTER_NAME"
  clusterctl get kubeconfig "$CLUSTER_NAME" > "$HOME/.kube/$CLUSTER_NAME-$1"
  export KUBECONFIG="$HOME/.kube/$CLUSTER_NAME-$1"
  kubectl get nodes
}

create_cluster "first"
kind delete clusters "$CLUSTER_NAME-bootstrap"
create_cluster "second"

