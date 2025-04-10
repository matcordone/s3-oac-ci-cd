# Bucket S3 para almacenar artefactos del pipeline
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.project_name}-${var.environment}-pipeline-artifacts"
}

# Rol IAM para CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.environment}-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
    }]
  })
}

# Política para CodePipeline
resource "aws_iam_policy" "codepipeline_policy" {
  name = "${var.project_name}-${var.environment}-pipeline-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_bucket.arn,
          "${aws_s3_bucket.codepipeline_bucket.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.website.arn,
          "${aws_s3_bucket.website.arn}/*"
        ]
        Effect = "Allow"
      },
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.cloudfront_invalidation.arn
        Effect   = "Allow"
      },
      {
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = var.connection_arn
        Effect   = "Allow"
      }
    ]
  })
}

# Adjuntar la política al rol
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# Pipeline V2
resource "aws_codepipeline" "website_pipeline" {
  name          = "${var.project_name}-${var.environment}-pipeline"
  role_arn      = aws_iam_role.codepipeline_role.arn
  pipeline_type = "V2" # Usamos Pipeline V2 para mejor desempeño

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  # Etapa Source - Obtiene el código del repositorio GitHub
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.connection_arn
        FullRepositoryId     = "${var.github_owner}/${var.github_repo}"
        BranchName           = var.github_branch
      }
    }
  }

  # Etapa Deploy - Copia el index.html al bucket S3
  stage {
    name = "Deploy"

    action {
      name            = "DeployToS3"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.website.id
        Extract    = "false"
        ObjectKey  = "index.html"
        CannedACL  = "private" # Privado para cumplir con OAC
        # Esta ruta depende de dónde está tu index.html en el repositorio
      }
    }
  }

  # Etapa de invalidación - Invoca la Lambda
  stage {
    name = "Invalidate"

    action {
      name     = "InvalidateCache"
      category = "Invoke"
      owner    = "AWS"
      provider = "Lambda"
      version  = "1"

      configuration = {
        FunctionName = aws_lambda_function.cloudfront_invalidation.function_name
      }
    }
  }
}