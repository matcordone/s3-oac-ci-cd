# Rol IAM para la función Lambda
resource "aws_iam_role" "lambda_invalidation_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Política para la función Lambda
resource "aws_iam_policy" "lambda_invalidation_policy" {
  name        = "${var.project_name}-${var.environment}-lambda-policy"
  description = "Permite a Lambda invalidar CloudFront y escribir logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult"
        ]
        Effect   = "Allow"
        Resource = "*"
      }

    ]
  })
}

# Adjuntar la política al rol
resource "aws_iam_role_policy_attachment" "lambda_invalidation_attachment" {
  role       = aws_iam_role.lambda_invalidation_role.name
  policy_arn = aws_iam_policy.lambda_invalidation_policy.arn
}

# Archivo ZIP con el código de la función Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<EOF
import boto3
import os
import json
import time

def lambda_handler(event, context):
    try:
        # Obtener información del trabajo de CodePipeline
        job_id = event['CodePipeline.job']['id']
        
        # Obtener el ID de la distribución de CloudFront
        distribution_id = os.environ['CLOUDFRONT_DISTRIBUTION_ID']
        
        # Crear clientes de AWS
        cloudfront = boto3.client('cloudfront')
        codepipeline = boto3.client('codepipeline')
        
        # Referencia única para la invalidación
        caller_reference = f"lambda-invalidation-{int(time.time())}"
        
        print(f"Creando invalidación para la distribución {distribution_id}")
        
        # Crear la invalidación
        response = cloudfront.create_invalidation(
            DistributionId=distribution_id,
            InvalidationBatch={
                'Paths': {
                    'Quantity': 1,
                    'Items': ['/index.html']
                },
                'CallerReference': caller_reference
            }
        )
        
        invalidation_id = response['Invalidation']['Id']
        
        print(f"Invalidación creada con ID: {invalidation_id}")
        
        # Verificar que la invalidación se ha iniciado
        check_response = cloudfront.get_invalidation(
            DistributionId=distribution_id,
            Id=invalidation_id
        )
        
        status = check_response['Invalidation']['Status']
        print(f"Estado de la invalidación: {status}")
        
        # Notificar éxito a CodePipeline
        codepipeline.put_job_success_result(
            jobId=job_id,
            executionDetails={
                'summary': f"Invalidación de CloudFront creada con éxito: {invalidation_id}",
                'externalExecutionId': invalidation_id,
                'percentComplete': 100
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': "Invalidación iniciada con éxito",
                'invalidationId': invalidation_id,
                'status': status
            })
        }
    except Exception as e:
        print(f"Error al crear invalidación: {str(e)}")
        
        # Si tenemos información del trabajo, notificar el fallo a CodePipeline
        if 'CodePipeline.job' in event and 'id' in event['CodePipeline.job']:
            try:
                job_id = event['CodePipeline.job']['id']
                codepipeline = boto3.client('codepipeline')
                codepipeline.put_job_failure_result(
                    jobId=job_id,
                    failureDetails={
                        'type': 'JobFailed',
                        'message': str(e)
                    }
                )
            except Exception as cp_error:
                print(f"Error al reportar fallo a CodePipeline: {str(cp_error)}")
        
        # Devolvemos un código de error
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': "Error al crear invalidación",
                'error': str(e)
            })
        }
EOF
    filename = "lambda_function.py"
  }
}

# Función Lambda
resource "aws_lambda_function" "cloudfront_invalidation" {
  function_name    = "${var.project_name}-${var.environment}-cf-invalidation"
  role             = aws_iam_role.lambda_invalidation_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      CLOUDFRONT_DISTRIBUTION_ID = aws_cloudfront_distribution.website.id
    }
  }
}