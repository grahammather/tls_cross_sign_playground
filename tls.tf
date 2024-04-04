/**
 * Copyright © 2014-2022 HashiCorp, Inc.
 *
 * This Source Code is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this project, you can obtain one at http://mozilla.org/MPL/2.0/.
 *
 */

# ===================
# Root CA

# Generate a private key so you can create a CA cert with it.
resource "tls_private_key" "root_2023" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a CA cert with the private key you just generated.
resource "tls_self_signed_cert" "root_2023" {
  private_key_pem = tls_private_key.root_2023.private_key_pem

  subject {
    common_name = "2023 Root CA"
  }

  validity_period_hours = 8760 

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true

}

# ===================
# 2024 Root CA

# Generate a private key so you can create a CA cert with it.
resource "tls_private_key" "root_2024" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a CA cert with the private key you just generated.
resource "tls_self_signed_cert" "root_2024" {
  private_key_pem = tls_private_key.root_2024.private_key_pem

  subject {
    common_name = "2024 Root CA"
  }

  validity_period_hours = 8760 

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true

}

# ===================
# Intermediate CA

# Generate a private key so you can create a CA cert with it.
# This is the key material for both int_2023 and int_2024
resource "tls_private_key" "int" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a CA cert with the private key you just generated.
resource "tls_cert_request" "int_2023" {
  private_key_pem = tls_private_key.int.private_key_pem

  subject {
    common_name = "Intermediate CA"
  }
}

resource "tls_locally_signed_cert" "int_2023" {
  cert_request_pem   = tls_cert_request.int_2023.cert_request_pem
  ca_private_key_pem = tls_private_key.root_2023.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_2023.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true
}

# ===================
# Cross-signed Intermediate CA
resource "tls_cert_request" "int_2024" {
  # use the old intermediate's key material
  private_key_pem = tls_private_key.int.private_key_pem

  subject {
    # CN must match the old Intermediate CA
    common_name = "Intermediate CA"
  }
}

# sign against 2024 root
resource "tls_locally_signed_cert" "int_2024" {
  cert_request_pem   = tls_cert_request.int_2024.cert_request_pem
  ca_private_key_pem = tls_private_key.root_2024.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_2024.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true
}


# =====================
# Leaf Cert

# Generate another private key. This one will be used
# To create the certs on your nodes
resource "tls_private_key" "leaf" {
  algorithm = "RSA"
  rsa_bits  = 2048

}

resource "tls_cert_request" "leaf" {
  private_key_pem = tls_private_key.leaf.private_key_pem

  subject {
    common_name = "${var.product}.server.com"
  }

  dns_names = concat(var.shared_sans, [
    "localhost",
  ])

  ip_addresses = [
    "127.0.0.1",
  ]
}

resource "tls_locally_signed_cert" "leaf" {
  cert_request_pem   = tls_cert_request.leaf.cert_request_pem
  ca_private_key_pem = tls_private_key.int.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.int_2023.cert_pem

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]

}


resource "local_file" "root_2023" {
  content  = tls_self_signed_cert.root_2023.cert_pem
  filename = "${var.output_dir}/${var.product}-ca-2023.pem"
}

resource "local_file" "root_2024" {
  content  = tls_self_signed_cert.root_2024.cert_pem
  filename = "${var.output_dir}/${var.product}-ca-2024.pem"
}


resource "local_file" "int_2023" {
  content  = tls_locally_signed_cert.int_2023.cert_pem
  filename = "${var.output_dir}/${var.product}-int-2023.pem"
}

resource "local_file" "int_2024" {
  content  = tls_locally_signed_cert.int_2024.cert_pem
  filename = "${var.output_dir}/${var.product}-int_2024.pem"
}

resource "local_file" "leaf" {
  content  = join("", [tls_locally_signed_cert.leaf.cert_pem, tls_locally_signed_cert.int_2023.cert_pem, tls_locally_signed_cert.int_2024.cert_pem])
  filename = "${var.output_dir}/${var.product}-crt.pem"
}

resource "local_file" "leaf_key" {
  content  = tls_private_key.leaf.private_key_pem
  filename = "${var.output_dir}/${var.product}-key.pem"
}

