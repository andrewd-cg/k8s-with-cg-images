#!/bin/bash

### Had to add this as kubectl wouldn't work during the master script execution without it - guess it wasnt set/available yet
export KUBECONFIG=/etc/kubernetes/admin.conf

### Install Calico Network Plugin
#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

### Install Flannel Network Plugin
VMUSER=`grep 1000 /etc/passwd | cut -d ":" -f1` # Get the vmuser which should have id 1000

cd /home/$VMUSER/k8s-build-scripts
wget https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
sed -i 's|ghcr.io/flannel-io|registry.andrewd.dev/flannel-io-cg|g' kube-flannel.yml
kubectl apply -f kube-flannel.yml