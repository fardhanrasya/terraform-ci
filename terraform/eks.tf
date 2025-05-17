module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0" # Menggunakan versi 5.x yang lebih baru

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # Menggunakan single NAT gateway untuk menghemat biaya
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Menambahkan tag yang diperlukan untuk EKS
  private_subnet_tags = {
    "kubernetes.io/cluster/test-eks"  = "shared"
    "kubernetes.io/role/internal-elb" = 1
  }


  public_subnet_tags = {
    "kubernetes.io/cluster/test-eks" = "shared"
    "kubernetes.io/role/elb"         = 1
  }


  tags = {
    Terraform                        = "true"
    Environment                      = "dev"
    "kubernetes.io/cluster/test-eks" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = "test-eks"
  cluster_version                = "1.27"
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # IAM Role untuk service account
  enable_irsa = true

  # CloudWatch logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Node security group
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_groups = {
    default = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3.micro"]
      capacity_type  = "SPOT"

      labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      tags = {
        Environment = "dev"
        Terraform   = "true"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}