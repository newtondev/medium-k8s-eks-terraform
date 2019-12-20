resource "aws_vpc" "eks_cluster" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.eks_cluster.id
  cidr_block              = "10.10.${10+count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.eks_cluster.id
  cidr_block              = "10.10.${20+count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.cluster_name}-private-subnet"
  }
}

resource "aws_internet_gateway" "eks_cluster" {
  vpc_id = aws_vpc.eks_cluster.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_eip" "eks_cluster_nat_gw" {
  count = length(aws_subnet.public)
  vpc   = true

  tags = {
    Name = "${var.cluster_name}-nat-gw"
  }
}

resource "aws_nat_gateway" "eks_cluster" {
  count         = length(aws_subnet.public)
  allocation_id = element(aws_eip.eks_cluster_nat_gw.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [ aws_internet_gateway.eks_cluster, aws_eip.eks_cluster_nat_gw ]

  tags = {
    Name = "${var.cluster_name}-nat-gw"
  }
}

resource "aws_route_table" "eks_cluster_public" {
  vpc_id     = aws_vpc.eks_cluster.id
  depends_on = [ aws_internet_gateway.eks_cluster ]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_cluster.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route_table" "eks_cluster_private" {
  vpc_id     = aws_vpc.eks_cluster.id
  depends_on = [ aws_nat_gateway.eks_cluster ]

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.eks_cluster.*.id, 0)
  }

  tags = {
    Name = "${var.cluster_name}-private-rt"
  }
}

resource "aws_route_table_association" "eks_cluster_public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.eks_cluster_public.id
  depends_on     = [ aws_subnet.public, aws_route_table.eks_cluster_public ]
}

resource "aws_route_table_association" "eks_cluster_private" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.eks_cluster_private.id
  depends_on     = [ aws_subnet.private, aws_route_table.eks_cluster_private ]
}

resource "aws_security_group" "eks_cluster_private_unrestricted_access" {
  name        = "${var.cluster_name}-private-unrestricted-access"
  description = "Access to all IPs and ports on private network."
  vpc_id      = aws_vpc.eks_cluster.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-private-unrestricted-access"
  }
}
