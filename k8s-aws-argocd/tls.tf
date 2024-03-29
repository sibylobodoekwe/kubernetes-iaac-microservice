data "kubectl_path_documents" "cert_crd" {
  pattern = "./scripts/cert-man.crd.yaml"
}

resource "kubectl_manifest" "cert_crd" {
  for_each  = toset(data.kubectl_path_documents.cert_crd.documents)
  yaml_body = each.value
}


#tls
resource "google_iam_policy" "cert_policy" {
  name        = "cert-policy"
  description = "policy for the cert manager"

  policy = file("./scripts/policy.json")
}

resource "google_iam_user_policy_attachment" "test-attach" {
  user       = data.aws_iam_user.example.user_name
  policy_arn = google_iam_policy.cert_policy.arn
}

resource "helm_release" "cert_man" {
  name             = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "version"
    value = "v1.11.0"
  }

  # set {
  #   name  = "installCRDs"
  #   value = true
  # }   

  depends_on = [
    kubectl_manifest.cert_crd
  ]
}

data "kubectl_path_documents" "cert" {
  pattern = "./cert-scripts/prod*.yaml"
}

resource "kubectl_manifest" "cert" {
  for_each  = toset(data.kubectl_path_documents.cert.documents)
  yaml_body = each.value


  depends_on = [
    helm_release.cert_man,
    helm_release.ingress,
    google_dns_record_set.site_domain
  ]
}



