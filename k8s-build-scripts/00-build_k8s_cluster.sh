if [ -z "$3" ]; then
  echo "Usage: sudo ./00-build_k8s_cluster.sh MASTER|WORKER K8S_VERSION IMAGE_REPO"
  echo "Example: sudo ./00-build_k8s_cluster.sh MASTER 1.25.5-00 registry.andrewd.dev/kube-cg"
  exit 1
fi

DIR="$(cd "$(dirname "$0")" && pwd)"

$DIR/01-prepare_node.sh
$DIR/02-install_containerd.sh
$DIR/03-install_k8s.sh $2

if [ $1 = "MASTER" ]; then
  $DIR/04-bootstrap_masternode.sh $3
  $DIR/05-install_cni.sh
  $DIR/06-generate_join_command.sh
fi
