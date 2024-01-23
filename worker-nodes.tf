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

resource "aws_autoscaling_group" "eks_worker_group" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = ["subnet-0d29699fce454a478","subnet-076f0b0a8f717c81f"]

  # Specify the EKS-optimized AMI. Use the AWS SSM parameter to get the latest AMI ID
  launch_configuration = aws_launch_configuration.eks_worker_config.name

  tag {
    key                 = "kubernetes.io/cluster/volley"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "eks-worker-node"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "eks_worker_config" {
  name_prefix   = "eks-worker-"
  instance_type = "t3.medium"
  image_id      = data.aws_ami.eks_worker.id  # Use data source to fetch the latest EKS-optimized AMI
  key_name = "eks-worker-nodes"
  iam_instance_profile = aws_iam_instance_profile.eks_worker_instance_profile.name

  lifecycle {
    create_before_destroy = true
  }
}


# Data source to fetch the latest EKS-optimized AMI
data "aws_ami" "eks_worker" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-*"]  # Adjust based on the EKS version and region
  }

  owners = ["602401143452"]  # AWS account ID for EKS AMIs
}
