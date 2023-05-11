provider "aws" {
  region = "us-west-2"
}

resource "aws_codebuild_project" "my_project" {
  name          = "my-project"
  service_role  = "arn:aws:iam::124288123671:role/awsrolecodebuild"
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
    location        = "my-source-location"
    git_clone_depth = 1
  }
}

resource "aws_codepipeline" "my_pipeline" {
  name     = "my-pipeline"
  role_arn = "arn:aws:iam::124288123671:role/awsrolecodepipeline"

  artifact_store {
    location = "my-artifact-bucket"
    type     = "S3"
    encryption_key {
      id   = "my-kms-key"
      type = "KMS"
    }
  }

  stage {
    name = "Source"
    action {
      name            = "Source"
      category        = "Source"
      owner           = "ThirdParty"
      provider        = "GitHub"
      version         = "1"
      output_artifacts = ["source_output"]
      configuration {
        Owner          = "my-org"
        Repo           = "my-repo"
        Branch         = "main"
        OAuthToken     = var.github_token
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["build_output"]
      version         = "1"
      configuration {
        ProjectName = aws_codebuild_project.my_project.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration {
        ClusterName = "my-ecs-cluster"
        ServiceName = "my-ecs-service"
        FileName   = "imagedefinitions.json"
      }
    }
  }
}
