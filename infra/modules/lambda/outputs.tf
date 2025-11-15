# Outputs del módulo Lambda

output "function_name" {
  description = "Nombre de la función Lambda"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN de la función Lambda"
  value       = aws_lambda_function.this.arn
}

output "function_invoke_arn" {
  description = "ARN de invocación de la función Lambda (para API Gateway)"
  value       = aws_lambda_function.this.invoke_arn
}

output "function_qualified_arn" {
  description = "ARN cualificado de la función Lambda (incluye versión)"
  value       = aws_lambda_function.this.qualified_arn
}

output "function_version" {
  description = "Versión de la función Lambda"
  value       = aws_lambda_function.this.version
}

output "role_arn" {
  description = "ARN del rol IAM de la función Lambda"
  value       = aws_iam_role.lambda.arn
}

output "role_name" {
  description = "Nombre del rol IAM de la función Lambda"
  value       = aws_iam_role.lambda.name
}

output "log_group_name" {
  description = "Nombre del CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN del CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.lambda.arn
}
