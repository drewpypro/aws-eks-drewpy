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
  content = "{{NLB_CNAME}}"
  ttl     = 1
  proxied = true

}
