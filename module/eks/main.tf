resource "aws_iam_role" "cluster_role" {
  name = "cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
            Service = "eks.amazonaws.com"
            }
        }
        ]
    })

    tags = {
        env = var.env
    }
  
}
    resource "aws_iam_policy_attachment" "cluster_policy_attachment" {
        name       = "cluster-policy-attachment"
        policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
        roles      = [aws_iam_role.cluster_role.name]
      
    }
 
 data "aws_vpc" "default_vpa" {
    default = true
   
 }

 data "aws_subnets" "my_subnets" {
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default_vpa]
    }
 }


resource "aws_eks_cluster" "my_cluster" {
  name = "my-cluster"

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster_role.arn
  version  = "1.31"

  vpc_config {
    subnet_ids = data.aws_subnets.my_subnets.ids
        
    
  }

depends_on = [
    aws_iam_policy_attachment.cluster_policy_attachment
    ]
timeouts {
    create = "20"
  
}
}

resource "aws_iam_policy_attachment" "node_policy_attachment" {
    name       = "node-policy-attachment"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    roles      = [aws_iam_role.cluster_role]
  
}

  resource "aws_iam_policy_attachment" "cluster_node_policy_attachment" {
    name       = "cluster-node-policy-attachment"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    roles      = [aws_iam_role.cluster_role.name]
  
}
resource "aws_iam_policy_attachment" "node_policy_attachment_ec2" {
    name       = "node-policy-attachment1"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
    roles      = [aws_eks_cluster.my_cluster.name]
  
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "my_node_group"
  node_role_arn   = aws_eks_cluster.my_cluster.role_arn
  subnet_ids      = data.aws_subnets.my_subnets.ids
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }


 update_config {
   max_unavailable = 1
 }

 depends_on = [
    aws_iam_policy_attachment.node_policy_attachment,
    aws_iam_policy_attachment.cluster_node_policy_attachment,
    aws_iam_policy_attachment.node_policy_attachment_ec2
 ]
 timeouts {
   create = 20
 }
}

