# Sitio Web Estático S3 con CloudFront y CI/CD

Este proyecto implementa un sitio web estático en AWS usando:
- Amazon S3 para almacenamiento
- CloudFront para distribución de contenido con OAC (Origin Access Control)
- AWS CodePipeline para CI/CD automatizado
- Lambda para invalidación de caché

## Arquitectura
GitHub -> CodePipeline -> S3 -> CloudFront -> Usuarios
|
v
Lambda (Invalidación)

## Prerrequisitos

- AWS CLI configurado
- Terraform instalado
- Conexión GitHub configurada en AWS

## Despliegue

1. Configura la conexión GitHub en AWS CodeConnections
2. Actualiza `terraform.tfvars` con el ARN de la conexión
3. Inicializa Terraform: *terraform init*
4. Despliega la infraestructura: *terraform apply*

## Uso

Después del despliegue, el sitio estará disponible en la URL proporcionada en los outputs de Terraform. Cada vez que se actualice el archivo index.html en el repositorio, el pipeline se activará automáticamente, actualizará el contenido y invalidará la caché de CloudFront.