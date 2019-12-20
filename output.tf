output "vpc_id" {
  value = aws_vpc.eks_cluster.id
}

output "vpc_cidr" {
  value = aws_vpc.eks_cluster.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}

output "private_unrestricted_security_group_id" {
  value = aws_security_group.eks_cluster_private_unrestricted_access.id
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: ${data.aws_caller_identity.current.arn}
      username: ${data.aws_caller_identity.current.user_id}
      groups:
        - system:masters
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.instance.endpoint}
    certificate-authority-data: ${aws_eks_cluster.instance.certificate_authority.0.data}
  name: ${aws_eks_cluster.instance.arn}
contexts:
- context:
    cluster: ${aws_eks_cluster.instance.arn}
    user: ${aws_eks_cluster.instance.arn}
  name: ${var.cluster_name}
current-context: ${var.cluster_name}
kind: Config
preferences: {}
users:
- name: ${aws_eks_cluster.instance.arn}
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      env: null
      args:
        - "token"
        - "-i"
        - "${var.cluster_name}"
KUBECONFIG
}
