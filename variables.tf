variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "vpc_id" {}
variable "subnets" {}
variable "vpce_whitelisted_accounts" {}
variable "kafka_instance_ids" {}
variable "kafka_broker_count" {}
variable "kafka_port" {
    default = "6000"
}
