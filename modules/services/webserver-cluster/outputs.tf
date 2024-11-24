output "public_ip" {
  value       = aws_instance.instance.public_ip
  description = "The public IP address of the web server"
}

# Output the domain name of application load balancer
output "application_lb_dns_name" {
  value       = aws_lb.application-lb.name
  description = "The domain name of the load balancer"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.asg-lb.name
  description = "The name of the auto scaling group"
}

output "application_lb_security_group_id" {
  value       = aws_security_group.sg-application-lb.id
  description = "The ID of the Security group attached to the load balancer"
}
