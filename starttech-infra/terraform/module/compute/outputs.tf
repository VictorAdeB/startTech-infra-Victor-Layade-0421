output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "redis_endpoint" {
  description = "Redis endpoint for backend application"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}