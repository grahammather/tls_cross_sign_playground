output "ca" {
    value = "${var.output_dir}/${var.product}-ca.pem"
}

output "cert" {
    value = "${var.output_dir}/${var.product}-crt.pem"
}

output "key" {
    value = "${var.output_dir}/${var.product}-key.pem"
}