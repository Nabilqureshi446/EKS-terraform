resource "aws_iam_role" "my_new_role" {
  name = "my-new-role"

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
        name       = "cluster_policy_attachment"
        policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
        roles      = [aws_iam_role.my_new_role.name]
      
    }
 
 data "aws_vpc" "default_vpa" {
    default = true
   
 }

 data "aws_subnets" "my_subnets" {
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default_vpa.id]
    }
 }


resource "aws_eks_cluster" "my_cluster" {
  name =  "my_cluster"

 

  role_arn = aws_iam_role.my_new_role.arn
  version  = "1.34"

  vpc_config {
    subnet_ids = data.aws_subnets.my_subnets.ids
        
    
  }

depends_on = [
    aws_iam_policy_attachment.cluster_policy_attachment
    ]
timeouts {
    create = "20m"
  
}
}

resource "aws_iam_role" "node_role" {
  name = "node_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    env = var.env
  }
}


resource "aws_iam_policy_attachment" "node_policy_attachment" {
    name       = "node-policy-attachment"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    roles      = [aws_eks_cluster.my_cluster]
  
}

  resource "aws_iam_policy_attachment" "cluster_node_policy_attachment" {
    name       = "cluster-node-policy-attachment"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    roles      = [aws_iam_role.my_new_role.name]
  
}
resource "aws_iam_policy_attachment" "node_policy_attachment1" {
    name       = "node-policy-attachment1"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
    roles      = [aws_iam_role.node_role.name]
  
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.my_cluster.name
  node_group_name = "my_node_group"
  node_role_arn   = aws_iam_role.node_role.arn
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
    aws_iam_policy_attachment.node_policy_attachment1
 ]
 timeouts {
   create = "20m"
   
 }
}

