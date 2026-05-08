output "certificate_arn" {
  description = "ACM certificate ARN for ALB ingress."
  value       = var.create_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : null
}

output "alb_ingress_annotations" {
  description = "Suggested Kubernetes Ingress annotations for AWS Load Balancer Controller."
  value = {
    "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"  = "ip"
    "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80},{\"HTTPS\":443}]"
    "alb.ingress.kubernetes.io/ssl-redirect" = "443"
    "alb.ingress.kubernetes.io/certificate-arn" = (
      var.create_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : "PLACEHOLDER_CERTIFICATE_ARN"
    )
  }
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID used for this region."
  value       = data.aws_route53_zone.this.zone_id
}
