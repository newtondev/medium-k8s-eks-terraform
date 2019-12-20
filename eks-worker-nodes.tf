resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = {
    Name = "${var.cluster_name}-node"
  }
}

resource "aws_iam_policy" "eks_cluster_autoscaling_policy" {
  name = "${var.cluster_name}-cluster-autoscaler"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:DescribeTags",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:DescribeTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaling_policy" {
  policy_arn = aws_iam_policy.eks_cluster_autoscaling_policy.arn
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_instance_profile" "eks_node" {
  name = var.cluster_name
  role = aws_iam_role.eks_node.name
}

resource "aws_security_group" "eks_node" {
  name        = "${var.cluster_name}-node"
  description = "Security group for all nodes in the cluster."
  vpc_id      = aws_vpc.eks_cluster.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
    "Name", "${var.cluster_name}-node",
    "kubernetes.io/cluster/${var.cluster_name}", "owned",
  )
}

resource "aws_security_group_rule" "eks_node_ingress_self" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_node.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane."
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "TCP"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_cluster.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_node_https_cluster" {
  description              = "Allow worker Kubelets and pods to communicate via HTTPS to cluster control plane."
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_cluster.id
  type                     = "ingress"
}

data "template_file" "userdata-nodes" {
  template = file("userdata-node.tpl")
  vars = {
    cluster_endpoint    = aws_eks_cluster.instance.endpoint
    cluster_certificate = aws_eks_cluster.instance.certificate_authority.0.data
    cluster_name        = aws_eks_cluster.instance.name
  }
}

resource "aws_launch_configuration" "eks-node" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.eks_node.name
  image_id                    = ""
  instance_type               = "m5.xlarge"
  key_name                    = var.key_pair_name
  name_prefix                 = "${var.cluster_name}-"
  security_groups             = [ aws_security_group.eks_node.id ]
  user_data_base64            = base64encode(data.template_file.userdata-nodes.rendered)

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_size           = "50"
    volume_type           = "gp2"
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "eks_node" {
  desired_capacity     = 3
  launch_configuration = aws_launch_configuration.eks-node.id
  max_size             = 5
  min_size             = 3
  name                 = "${var.cluster_name}-nodes"
  vpc_zone_identifier  = concat(aws_subnet.private.*.id)

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-nodes"
      propagate_at_launch = true
    },
    {
      key                 = "kubernetes.io/cluster/tmsdp-eks"
      value               = "owned"
      propagate_at_launch = true
    }
  ]
}
