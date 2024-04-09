# variable related to TLS cert generation
variable "shared_sans" {
  type        = list(string)
  description = "This is a shared server name that the certs for all nodes contain. This is the same value you will supply as input to the installation module for the leader_tls_servername variable."
  default = []
}

variable "output_dir" {
  type = string
  default = "./test/local_test"
}

variable "product" {
  type = string
  default = "test"
}