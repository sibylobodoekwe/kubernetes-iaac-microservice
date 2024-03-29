#Provision Nginx Ingress Controller
resource "helm_release" "ingress" {
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
}

data "kubectl_path_documents" "ingress" {
  pattern = "./scripts/ingress.yaml"
}

resource "kubectl_manifest" "ingress" {
  for_each  = toset(data.kubectl_path_documents.ingress.documents)
  yaml_body = each.value

  depends_on = [
    kubectl_manifest.cert,
    google_dns_record_set.site_domain,
    helm_release.cert_man,
    kubectl_manifest.cert,
    kubectl_manifest.mern,
    kubectl_manifest.sock_shop
  ]
}
