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
  name     = "my-pipeline"
  role_arn = "arn:aws:iam::124288123671:role/awsrolecodebuld"
  
  artifact_store {
    location = aws_s3_bucket.artifacts_bucket.bucket
    type     = "S3"
  }
  
  stage {
    name = "Source"
    
    action {
      name            = "SourceAction"
      category        = "Source"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      output_artifacts = ["SourceArtifact"]
      
      configuration = {
        BucketName = aws_s3_bucket.source_bucket.bucket
        ObjectKey  = "source.zip"
      }
    }
  }
  
  stage {
    name = "Build"
    
    action {
      name            = "BuildAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      
      configuration = {
        ProjectName = aws_codebuild_project.my_project.name
      }
    }
  }
  
  stage {
    name = "Deploy"
    
    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["BuildArtifact"]
      
      configuration = {
        BucketName = aws_s3_bucket.deploy_bucket.bucket
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
