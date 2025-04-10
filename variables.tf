# Variables generales
variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
}

# Variables para GitHub/CI/CD
variable "github_owner" {
  description = "Propietario del repositorio GitHub"
  type        = string
}

variable "github_repo" {
  description = "Nombre del repositorio GitHub"
  type        = string
}

variable "github_branch" {
  description = "Rama del repositorio a monitorear"
  type        = string
}

variable "connection_arn" {
  description = "ARN de la conexión AWS a GitHub"
  type        = string
}