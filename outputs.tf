output "ecs_cluster_id" {
  description = "ID of the created ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_cluster_arn" {
  description = "ARN of the created ECS cluster"
  value       = aws_ecs_cluster.ecs_cluster.arn
}

output "subnet_private" {
  value = [for s in data.aws_subnet.private : s.id]
}

output "subnet_public" {
  value = [for s in data.aws_subnet.public : s.id]
}


output "load_balancer_ip" {
  value = aws_lb.default.dns_name
}
