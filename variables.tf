variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "ssm_vpc_id" {
  type = string
}

variable "ssm_public_subnets" {
  type = list(string)
}

variable "ssm_private_subnets" {
  type = list(string)
}

variable "ssm_pod_subnets" {
  type = list(string)
}

variable "ssm_database_subnets" {
  type = list(string)
}

variable "k8s_version" {

}

variable "auto_scale_options" {
  type = object({
    min     = number
    max     = number
    desired = number
  })
}

variable "nodes_instance_sizes" {
  type = list(string)
}

variable "addon_cni_version" {
  type    = string
  default = "v1.23.0-eksbuild.1"
}

variable "addon_coredns_version" {
  type    = string
  default = "v1.13.2-eksbuild.11"
}

variable "addon_kubeproxy_version" {
  type    = string
  default = "v1.35.3-eksbuild.18"
}