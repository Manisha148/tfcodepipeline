provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = "my-source-bucket"
}

resource "aws_codebuild_project" "my_project" {
  name       = "my-project"
  source     = "${aws_s3_bucket.source_bucket.arn}"
  buildspec  = "${file("${path.module}/buildspec.yml")}"
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
  }
}

resource "aws_codepipeline" "my_pipeline" {
  name     = "my-pipeline"
  role_arn = "arn:aws:iam::1234567890:role/codepipeline-role"

  artifact_store {
    location = "my-artifact-store"
    type     = "S3"
  }

  stages {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["my_app"]
      configuration {
        Bucket = "${aws_s3_bucket.source_bucket.id}"
        Key    = "my-app.zip"
      }
    }
  }

  stages {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["my_app"]
      output_artifacts = ["my_build"]
      configuration {
        ProjectName = "${aws_codebuild_project.my_project.name}"
      }
    }
  }

  stages {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ElasticBeanstalk"
      version          = "1"
      input_artifacts  = ["my_build"]
      configuration {
        ApplicationName = "my-app"
        EnvironmentName = "my-env"
      }
    }
  }
}
