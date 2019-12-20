#!/bin/bash
/etc/eks/bootstrap.sh --apiserver-endpoint '${cluster_endpoint}' \
--b64-cluster-ca '${cluster_certificate}' '${cluster_name}'  \
--kubelet-extra-args '--kube-reserved cpu=250m,memory=1Gi,ephemeral-storage=1Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'
