terraform {
  required_version = ">= 1.2.1"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
    }
  }
}
