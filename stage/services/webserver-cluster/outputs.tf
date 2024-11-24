output "application_lb_dns_name" {
  value       = module.webserver_cluster.application_lb_dns_name
  description = "The domain name of the load balancer"
}
