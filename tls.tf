resource "tls_private_key" "root_2023_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "root_2023" {
  private_key_pem = tls_private_key.root_2023_key.private_key_pem

  subject {
    common_name = "root_2023"
  }

  is_ca_certificate = true
  validity_period_hours = 87600
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "tls_private_key" "root_2024_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "root_2024" {
  private_key_pem = tls_private_key.root_2024_key.private_key_pem

  subject {
    common_name = "root_2024"
  }

  is_ca_certificate = true
  validity_period_hours = 87600
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}


resource "tls_private_key" "intermediate_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "intermediate_request" {
  private_key_pem = tls_private_key.intermediate_key.private_key_pem

  subject {
    common_name = "int_2023"
  }
}

resource "tls_locally_signed_cert" "intermediate_signed_by_root_2023" {
  cert_request_pem   = tls_cert_request.intermediate_request.cert_request_pem
  ca_private_key_pem = tls_private_key.root_2023_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_2023.cert_pem

  is_ca_certificate = true
  validity_period_hours = 43800
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "tls_locally_signed_cert" "intermediate_signed_by_root_2024" {
  cert_request_pem   = tls_cert_request.intermediate_request.cert_request_pem
  ca_private_key_pem = tls_private_key.root_2024_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_2024.cert_pem

  is_ca_certificate = true
  validity_period_hours = 43800
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "tls_private_key" "leaf_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "leaf_request" {
  private_key_pem = tls_private_key.leaf_key.private_key_pem

  subject {
    common_name = "leaf"
  }

  dns_names = concat(
    ["localhost"],
    var.shared_sans
  )

  ip_addresses = ["127.0.0.1"]
}

resource "tls_locally_signed_cert" "leaf_signed_by_intermediate" {
  cert_request_pem   = tls_cert_request.leaf_request.cert_request_pem
  ca_private_key_pem = tls_private_key.intermediate_key.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate_signed_by_root_2023.cert_pem

  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
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
  content  = tls_locally_signed_cert.intermediate_signed_by_root_2023.cert_pem
  filename = "${var.output_dir}/${var.product}-int-2023.pem"
}

resource "local_file" "int_2024" {
  content  = tls_locally_signed_cert.intermediate_signed_by_root_2024.cert_pem
  filename = "${var.output_dir}/${var.product}-int-2024.pem"
}

resource "local_file" "leaf" {
  content  = tls_locally_signed_cert.leaf_signed_by_intermediate.cert_pem
  filename = "${var.output_dir}/${var.product}-leaf.pem"
}

# ==================
# Server serves just the leaf 
#
# resource "local_file" "bundle" {
#   content  = tls_locally_signed_cert.leaf_signed_by_intermediate.cert_pem
#   filename = "${var.output_dir}/${var.product}-crt.pem"
# }

# ==================
# Server serves leaf and 2023 intermediate
#
# resource "local_file" "bundle" {
#   content  = join("", [tls_locally_signed_cert.leaf_signed_by_intermediate.cert_pem, tls_locally_signed_cert.intermediate_signed_by_root_2023.cert_pem])
#   filename = "${var.output_dir}/${var.product}-crt.pem"
# }

# ==================
# Server serves leaf, 2023 intermediate. and cross-signed 2024 intermediate
#
resource "local_file" "bundle" {
  content  = join("", [tls_locally_signed_cert.leaf_signed_by_intermediate.cert_pem, tls_locally_signed_cert.intermediate_signed_by_root_2023.cert_pem, tls_locally_signed_cert.intermediate_signed_by_root_2024.cert_pem])
  filename = "${var.output_dir}/${var.product}-crt.pem"
}

resource "local_file" "leaf_key" {
  content  = tls_private_key.leaf_key.private_key_pem
  filename = "${var.output_dir}/${var.product}-key.pem"
}

