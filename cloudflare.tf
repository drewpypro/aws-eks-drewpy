resource "cloudflare_record" "istio_ingress_records" {
  for_each = {
    "cormorant" = "cormorant.drewpy.pro"
    "anhinga"   = "anhinga.drewpy.pro"
    "gannet"    = "gannet.drewpy.pro"
    "argocd"    = "argocd.drewpy.pro"
    "egress"    = "egress.drewpy.pro"
  }

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = each.value
  type    = "CNAME"
  content = aws_lb.istio_ingress_nlb.dns_name
  ttl     = 60
  proxied = true

  depends_on = [aws_lb.istio_ingress_nlb]
}