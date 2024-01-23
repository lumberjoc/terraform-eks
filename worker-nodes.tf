resource "aws_iam_role" "eks_worker_role" {
  name = "eks-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_connect" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_worker_role.name
}

resource "aws_iam_instance_profile" "eks_worker_instance_profile" {
  name = "eks-worker-instance-profile"
  role = aws_iam_role.eks_worker_role.name
}

resource "aws_security_group" "eks_worker_sg" {
  name        = "eks-workers-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  # Allow inbound communication from the control plane and nodes within the VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]  # Adjust this to match your VPC CIDR
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-workers-sg"
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.volley.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_worker_role.arn
  subnet_ids      = [aws_subnet.eks_subnet1.id, aws_subnet.eks_subnet2.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  # Depending on your requirements, you can specify the AMI version, disk size, labels, taints, etc.
  # Example:
  # instance_types = ["t3.medium"]
  # disk_size      = 20

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_connect,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}


# resource "aws_autoscaling_group" "eks_worker_group" {
#   desired_capacity     = 2
#   max_size             = 3
#   min_size             = 1
#   vpc_zone_identifier  = ["subnet-0d29699fce454a478","subnet-076f0b0a8f717c81f"]

#   # Specify the EKS-optimized AMI. Use the AWS SSM parameter to get the latest AMI ID
#   launch_configuration = aws_launch_configuration.eks_worker_config.name

#   tag {
#     key                 = "kubernetes.io/cluster/volley"
#     value               = "owned"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "Name"
#     value               = "eks-worker-node"
#     propagate_at_launch = true
#   }
# }

# resource "aws_launch_configuration" "eks_worker_config" {
#   name_prefix   = "eks-worker-"
#   instance_type = "t3.medium"
#   image_id      = data.aws_ami.eks_worker.id  # Use data source to fetch the latest EKS-optimized AMI
#   key_name = "eks-worker-nodes"
#   iam_instance_profile = aws_iam_instance_profile.eks_worker_instance_profile.name
#   security_groups = [aws_security_group.eks_worker_sg.id]

#   lifecycle {
#     create_before_destroy = true
#   }
# }


# Data source to fetch the latest EKS-optimized AMI
data "aws_ami" "eks_worker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]  # Adjust based on the EKS version and region
  }

  owners = ["602401143452"]  # AWS account ID for EKS AMIs
}
