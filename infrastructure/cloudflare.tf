resource "cloudflare_record" "istio_ingress_records" {
  for_each = {
    "cormorant" = "cormorant-test.drewpy.pro"
    "anhinga"   = "anhinga-test.drewpy.pro"
    "gannet"    = "gannet-test.drewpy.pro"
    "argocd"    = "argocd-test.drewpy.pro"
    "egress"    = "egress-test.drewpy.pro"
  }

  zone_id = var.CLOUDFLARE_ZONE_ID
  name    = each.value
  type    = "CNAME"
  content = aws_lb.istio_ingress_nlb.dns_name
  ttl     = 1
  proxied = true

  depends_on = [aws_lb.istio_ingress_nlb]
}