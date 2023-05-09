# Create an S3 bucket for storing source code
resource "aws_s3_bucket" "source_bucket" {
  bucket = "my-source-bucket"
}

# Create an IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "my-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# Create an IAM policy for CodeBuild
resource "aws_iam_policy" "codebuild_policy" {
  name = "my-codebuild-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.source_bucket.arn}/*"
      }
    ]
  })
}

# Attach the IAM policy to the CodeBuild role
resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  policy_arn = aws_iam_policy.codebuild_policy.arn
  role       = aws_iam_role.codebuild_role.name
}

# Create a CodeBuild project
resource "aws_codebuild_project" "my_project" {
  name = "my-codebuild-project"

  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    name = "output"
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    type        = "LINUX_CONTAINER"
    image       = "aws/codebuild/standard:5.0"
  }

  source {
    type            = "S3"
    location        = "S3::${aws_s3_bucket.source_bucket.arn}"
    buildspec       = file("${path.module}/buildspec.yml")
    report_build_status = true
    insecure_ssl    = true
  }
}

# Create a CodePipeline pipeline
resource "aws_codepipeline" "my_pipeline" {
  name = "my-codepipeline"
  role_arn
