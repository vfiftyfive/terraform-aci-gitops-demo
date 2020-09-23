variable "username" {}
variable "password" {}
variable "url" {}
variable "epg_name" {}

locals {
  cluster_name     = "SJKube01"
  bd_name          = "aci-containers-SJKube01-pod-bd"
  default_epg_name = "aci-containers-default"
  anp_name         = "aci-containers-SJKube01"
}

provider "aci" {
  username = "${var.username}"
  password = "${var.password}"
  url      = "${var.url}"
  insecure = true
  version = "=0.3"
}

data "aci_tenant" "this" {
  name = "${local.cluster_name}"
}

data "aci_bridge_domain" "this" {
  tenant_dn = "${data.aci_tenant.this.id}"
  name      = "${local.bd_name}"
}

data "aci_application_profile" "this" {
  tenant_dn = "${data.aci_tenant.this.id}"
  name      = "${local.anp_name}"
}

data "aci_application_epg" "k8s_default" {
  application_profile_dn = "${data.aci_application_profile.this.id}"
  name                   = "${local.default_epg_name}"
}

data "aci_vmm_domain" "k8s_vmm" {
  provider_profile_dn = "uni/vmmp-Kubernetes"
  name                = "${local.cluster_name}"
}

resource "aci_application_epg" "this" {
  application_profile_dn       = "${data.aci_application_profile.this.id}"
  name                         = "${var.epg_name}"
  relation_fv_rs_sec_inherited = ["${data.aci_application_epg.k8s_default.id}"]
  relation_fv_rs_dom_att       = ["${data.aci_vmm_domain.k8s_vmm.id}"]
  relation_fv_rs_bd            = "${data.aci_bridge_domain.this.id}"
}

output "epg" {
  value = "${aci_application_epg.this.id}"
}