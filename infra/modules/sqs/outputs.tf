output "queue_id" {
  description = "ID de la cola SQS"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "ARN de la cola SQS"
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.this.url
}

output "queue_name" {
  description = "Nombre de la cola SQS"
  value       = aws_sqs_queue.this.name
}

output "dlq_arn" {
  description = "ARN de la Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "URL de la Dead Letter Queue"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}
