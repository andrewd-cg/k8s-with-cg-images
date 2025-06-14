# How to build a k8s cluster with Chainguard images using kubeadm

## Prerequisites

* Container Registry accessable by your nodes without authentication (we will mirror the images here)
* Docker or similar installed to pull, tag and push the images to your registry
* Kube nodes with containerd, kubelet, kubeadm, kubectl installed - See [K8 Docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
 > Note: Sample scripts I use to quickly build nodes and clusters are in [k8s-build-scripts](k8s-build-scripts/) for reference

## Mirror Chainguard images

### Get a list of pull strings that you need to end up with in your registry

```sh
kubeadm config images list --image-repository registry.andrewd.dev/kube-cg
```

Output will be something like this (depends on version of kubeadm)
```
registry.andrewd.dev/kube-cg/kube-apiserver:v1.31.9
registry.andrewd.dev/kube-cg/kube-controller-manager:v1.31.9
registry.andrewd.dev/kube-cg/kube-scheduler:v1.31.9
registry.andrewd.dev/kube-cg/kube-proxy:v1.31.9
registry.andrewd.dev/kube-cg/coredns:v1.11.3
registry.andrewd.dev/kube-cg/pause:3.10
registry.andrewd.dev/kube-cg/etcd:3.5.15-0
```

### Now pull the matching versions from Chainguard (note tags will be slightly different)
```sh
docker pull cgr.dev/chainguard-private/kubernetes-kube-apiserver:1.31.9
docker pull cgr.dev/chainguard-private/kubernetes-kube-controller-manager:1.31.9
docker pull cgr.dev/chainguard-private/kubernetes-kube-scheduler:1.31.9
docker pull cgr.dev/chainguard-private/kubernetes-kube-proxy:1.31.9
docker pull cgr.dev/chainguard-private/coredns:1.11.3
docker pull cgr.dev/chainguard-private/kubernetes-pause:1.33.1
docker pull cgr.dev/chainguard-private/etcd:3.5.15
```

### Tag the Chainguard images to match what is expected
```sh
docker tag cgr.dev/chainguard-private/kubernetes-kube-apiserver:1.31.9 registry.andrewd.dev/kube-cg/kube-apiserver:v1.31.9
docker tag cgr.dev/chainguard-private/kubernetes-kube-controller-manager:1.31.9 registry.andrewd.dev/kube-cg/kube-controller-manager:v1.31.9
docker tag cgr.dev/chainguard-private/kubernetes-kube-scheduler:1.31.9 registry.andrewd.dev/kube-cg/kube-scheduler:v1.31.9
docker tag cgr.dev/chainguard-private/kubernetes-kube-proxy:1.31.9 registry.andrewd.dev/kube-cg/kube-proxy:v1.31.9
docker tag cgr.dev/chainguard-private/coredns:1.11.3 registry.andrewd.dev/kube-cg/coredns:v1.11.3
docker tag cgr.dev/chainguard-private/kubernetes-pause:1.33.1 registry.andrewd.dev/kube-cg/pause:3.10
docker tag cgr.dev/chainguard-private/etcd:3.5.15 registry.andrewd.dev/kube-cg/etcd:3.5.15-0
```

### Push the images to your own registry with the tags kubeadm expects
```sh
docker push registry.andrewd.dev/kube-cg/kube-apiserver:v1.31.9
docker push registry.andrewd.dev/kube-cg/kube-controller-manager:v1.31.9
docker push registry.andrewd.dev/kube-cg/kube-scheduler:v1.31.9
docker push registry.andrewd.dev/kube-cg/kube-proxy:v1.31.9
docker push registry.andrewd.dev/kube-cg/coredns:v1.11.3
docker push registry.andrewd.dev/kube-cg/pause:3.10
docker push registry.andrewd.dev/kube-cg/etcd:3.5.15-0
```

## Update containerd config with pause container pull string
On your k8s nodes (this is included in my scripts) we need to update it to use the same pull string for the pause container as kubeadm

```sh
sudo sed -i '' 's|sandbox_image = .*|sandbox_image = "registry.andrewd.dev/kube-cg/pause:3.10"|' /etc/containerd/config.toml
```

## Install k8s compoenets 

### Run kubeadm init with your image repository
```sh
sudo kubeadm init --image-repository registry.andrewd.dev/kube-cg
```

## Install CNI
In this case I'm using flannel.

### Mirror Flannel from Chainguard to your registry

> Note: Have to use the -dev tag for the shell because Flannel requires the cp command on startup

```sh
docker pull cgr.dev/chainguard-private/flannel:0.27-dev
docker tag cgr.dev/chainguard-private/flannel:0.27-dev registry.andrewd.dev/flannel-io-cg/flannel:v0.27.0
docker push registry.andrewd.dev/flannel-io-cg/flannel:v0.27.0
```

### Build Chainguard flannel-cni-plugin image and push to your registry for later
Currently Chainguard doesn't have the flannel-cni image, but does have the package available in wolfi so lets build our own using the [Dockerfile.flannel-cni-plugin](Dockerfile.flannel-cni-plugin) in this repo

```
docker build -t registry.andrewd.dev/flannel-io-cg/flannel-cni-plugin:v1.7.1-flannel1 -f Dockerfile.flannel-cni-plugin .
docker push registry.andrewd.dev/flannel-io-cg/flannel-cni-plugin:v1.7.1-flannel1
```

### Grab the latest flannel.yml and swap out the image reference
If you're using my scripts, I've already done this in 05-install_cni.sh
```sh
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
sed -i '' 's|ghcr.io/flannel-io|registry.andrewd.dev/flannel-io-cg|g' kube-flannel.yml
```

## Join worker nodes
Run this on your master node to get a kubeadmin join command to run on your worker nodes
```sh
kubeadm token create --print-join-command
```