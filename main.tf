data "aws_eks_cluster" "staging" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "staging" {
  name = var.cluster_name
}

provider "kubernetes" {
  alias                  = "module"
  host                   = data.terraform_remote_state.infra_staging.outputs.eks.staging_use1.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.infra_staging.outputs.eks.staging_use1.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.staging.token
  load_config_file       = false
}

## IRSA for the service
# this is just to not have inline javascript... could just as easily be a HEREDOC in the
# `aws_iam_role` below
data "aws_iam_policy_document" "service_irsa_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.terraform_remote_state.infra_staging.outputs.eks.staging_use1.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.stack}:${var.stack}-${var.service}-sa"]
    }

    principals {
      identifiers = ["${data.terraform_remote_state.infra_staging.outputs.eks.staging_use1.eks.oidc_provider_arn}"]
      type        = "Federated"
    }
  }
}
# This creates the role and gives it the assume role policy from above
resource "aws_iam_role" "service_role" {
  name               = "${var.stack}-${var.service}-sa"
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.service_irsa_assume_role.json
}

resource "kubernetes_service_account" "revenue_sa" {
  provider                        = kubernetes.module
  automount_service_account_token = true
  metadata {
    name      = "${var.stack}-${var.service}-sa"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.account_id}:role/${aws_iam_role.service_role.name}"
    }
  }
}
