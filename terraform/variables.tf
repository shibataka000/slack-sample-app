variable "region" {
  default = "ap-northeast-1"
}
variable "profile" {
  default = "default"
}
variable "prefix" {}
variable "lambda_filename" {}
variable "lambda_handler" {}
variable "api_gateway_domain_name" {}
variable "acm_certificate_arn" {}
variable "route53_zone_id" {}
