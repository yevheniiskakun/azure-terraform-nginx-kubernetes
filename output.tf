output "nginx_ip" {
  value = kubernetes_service.custom-site.status[0].load_balancer[0].ingress[0].ip
}