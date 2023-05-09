provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = "my-source-bucket"
}

resource "aws_codebuild_project" "my_project" {
  name = "my-project"
  service_role = "arn:aws:iam::123456789012:role/service-role/codebuild-project-role"
  artifacts {
    type = "S3"
    location = aws_s3_bucket.source_bucket.bucket
  }
  source {
    type = "S3"
    location = aws_s3_bucket.source_bucket.bucket
  }
  environment {
    type = "LINUX_CONTAINER"
    image = "aws/codebuild/standard:4.0"
  }
  buildspec = file("${path.module}/buildspec.yml")
}

resource "aws_codepipeline" "my_pipeline" {
  name = "my-pipeline"
  role_arn = "arn:aws:iam::123456789012:role/pipeline-role"
  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type = "S3"
  }
  
  stage {
    name = "Source"
    action {
      name = "SourceAction"
      category = "Source"
      owner = "AWS"
      provider = "S3"
      version = "1"
      output_artifacts = ["SourceArtifact"]
      configuration {
        S3Bucket = aws_s3_bucket.source_bucket.bucket
        S3ObjectKey = "source.zip"
      }
    }
  }
  
  stage {
    name = "Build"
    action {
      name = "BuildAction"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      configuration {
        ProjectName = aws_codebuild_project.my_project.name
      }
    }
  }
  
  stage {
    name = "Deploy"
    action {
      name = "DeployAction"
      category = "Deploy"
      owner = "AWS"
      provider = "S3"
      version = "1"
      input_artifacts = ["BuildArtifact"]
      configuration {
        S3Bucket = aws_s3_bucket.deploy_bucket.bucket
        Extract = "true"
      }
    }
  }
}
resource "aws_codepipeline" "my_pipeline" {
  name     = "my-pipeline"
  role_arn = "${aws_iam_role.my_pipeline_role.arn}"

  # ... other pipeline configurations ...
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "my-artifact-bucket"
}

resource "aws_s3_bucket" "deploy_bucket" {
  bucket = "my-deploy-bucket"
}
