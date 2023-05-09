resource "aws_codebuild_project" "my_project" {
  name        = "my-project"
  description = "My CodeBuild project"
  
  source {
    type      = "S3"
    location  = aws_s3_bucket.source_bucket.bucket
    buildspec = file("${path.module}/buildspec.yml")
  }
  
  environment {
    type  = "LINUX_CONTAINER"
    
    resource "aws_codebuild_project" "my_project" {
    name          = "my-project"
    service_role  = arn:aws:iam::124288123671:role/awsrolecodebuld
    compute_type  = "BUILD_GENERAL1_SMALL" // or any other valid value
    buildspec     = file("${path.module}/buildspec.yml")
    image = "aws/codebuild/standard:5.0"
  # other configuration options for the project
    source {
    type            = "CODEPIPELINE"
    buildspec       = file("${path.module}/buildspec.yml")
    # other configuration options for the source
  }
}

  }
  
  artifacts {
    type = "S3"
    location = aws_s3_bucket.artifacts_bucket.bucket
    name = "my-project"
  }
}

resource "aws_codepipeline" "my_pipeline1" {
  name = "my-pipeline"

  # Define the source stage
  stage {
    name = "Source"
    action {
      # Define the configuration for the CodeCommit action
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration {
        RepositoryName = "my-repo"
        BranchName     = "main"
      }
    }
  }

  # Define the build stage
  stage {
    name = "Build"
    action {
      # Define the configuration for the CodeBuild action
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      configuration {
        ProjectName = "my-build-project"
      }
    }
  }

  # Define the deploy stage
  stage {
    name = "Deploy"
    action {
      # Define the configuration for the Elastic Beanstalk action
      name             = "DeployAction"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ElasticBeanstalk"
      version          = "1"
      input_artifacts  = ["BuildArtifact"]
      configuration {
        ApplicationName = "my-app"
        EnvironmentName = "my-env"
      }
    }
  }
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = "my-source-bucket"
}

resource "aws_s3_bucket" "artifacts_bucket" {
  bucket = "my-artifacts-bucket"
}

resource "aws_s3_bucket" "deploy_bucket" {
  bucket = "my-deploy-bucket"
}

resource "aws_iam_role" "pipeline_role" {
  name = "my-pipeline-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipelineFullAccess"
  role       = aws_iam_role.pipeline_role.name
}
