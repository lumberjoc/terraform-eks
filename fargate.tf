# IAM role for EKS Fargate pods
resource "aws_iam_role" "eks_fargate_role" {
  name = "eks_fargate_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      },
    ]
  })
}

# Policy attachment for the Fargate IAM role
resource "aws_iam_role_policy_attachment" "eks_fargate_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_role.name
}

# Fargate profile for the EKS cluster
resource "aws_eks_fargate_profile" "eks_fargate_profile" {
  cluster_name           = aws_eks_cluster.volley.name
  fargate_profile_name   = "eks-fargate-profile"
  pod_execution_role_arn = aws_iam_role.eks_fargate_role.arn

  subnet_ids = [aws_subnet.eks_subnet1.id, aws_subnet.eks_subnet2.id]

  selector {
    namespace = "kube-system" # Specify the namespace to run on Fargate
  }

  # Add additional selectors as needed
}
