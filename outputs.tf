output "website_bucket_name" {
  description = "Nombre del bucket S3 del sitio web"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución CloudFront"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "Dominio de CloudFront para acceder al sitio web"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "URL del sitio web"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "pipeline_name" {
  description = "Nombre del pipeline CI/CD"
  value       = aws_codepipeline.website_pipeline.name
}