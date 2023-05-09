provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = "my-source-bucket0098"
}

resource "aws_codebuild_project" "my_project" {
  name = "my-project"
  
  service_role = arn:aws:iam::124288123671:role/awsrolecodebuld
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  source {
    type = "S3"
    location = aws_s3_bucket.source_bucket.bucket
  }
  
  environment {
    type = "LINUX_CONTAINER"
    image = "aws/codebuild/standard:5.0"
  }
  
  buildspec = file("${path.module}/buildspec.yml")
}


resource "aws_codepipeline" "my_pipeline" {
  name = "my-pipeline"

  # ...

  role_arn = "arn:aws:iam::124288123671:role/awsrolecodebuld"
}


  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
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
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildArtifact"]

      configuration = {
        ApplicationName = aws_codedeploy_app.my_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.my_deployment_group.name
      }
    }
  }
}



resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "my-artifact-bucket"
  region = "eu-west-2"
}

resource "aws_s3_bucket" "deploy_bucket" {
  bucket = "my-deploy-bucket"
  region = "us-east-2"
}
