output "root_2023" {
    value = "${var.output_dir}/${var.product}-ca-2023.pem"
}
output "root_2024" {
    value = "${var.output_dir}/${var.product}-ca-2024.pem"
}

output "root_combined" {
    value = "${var.output_dir}/${var.product}-ca-combined.pem"
}

output "int_2023" {
    value = "${var.output_dir}/${var.product}-int-2023.pem"
}
output "int_2024" {
    value = "${var.output_dir}/${var.product}-int-2024.pem"
}

output "leaf_and_2023_int_bundle" {
    value = "${var.output_dir}/${var.product}-leaf-and-2023-int.pem"
}

output "leaf_and_xs_ints_bundle" {
    value = "${var.output_dir}/${var.product}-leaf-and-xs-ints.pem"
}

output "key" {
    value = "${var.output_dir}/${var.product}-key.pem"
}