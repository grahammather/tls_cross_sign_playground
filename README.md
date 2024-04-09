# How To

This is a module for learning about TLS cross signing. The idea is that you're trying to use cross-signed intermediate certificates to rotate the root CA for a service that's in production deployment. The problem that this solves is that if you change your PKI infrastructure to suddenly start serving leaf certificates signed with a net-new chain of trust, services that try to connect to your TLS-protected service without having received the new root CA will get TLS handshake errors.

## Prerequisites

### Terraform

Download and install [Terraform](https://releases.hashicorp.com/terraform/)

### Docker

In order to run the test server, you need [Docker](https://www.docker.com/) installed.

### Go

You need to be able to compile and run go programs. [Install Go](https://go.dev/dl/).

## Naming convention

The conceit of this module is that your existing resources are the "2023" version, and you want to migrate to the "2024" version.

[This tutorial](https://developer.hashicorp.com/vault/tutorials/secrets-management/pki-engine) walks you through something similar.

## Key Terraform Resources
The Terraform resources define the following:

### Root 2023 Certificate Authority
Self-signed cert, making it a root CA. This is the old root CA that needs to be rotated out.

### Root 2024 Certificate Authority
Self-signed cert, making it a root CA. This is the new root CA.

### Intermediate 2023 Certificate Authority
Intermediate cert signed by Root 2023

### Cross-signed Intermediate 2024 Certificate Authority
Intermediate CA that doesn't have its own private key, but instead is generated using the _Intermediate 2023 Certificate Authority_'s private key. Also has the exact same subject name as the _Intermediate 2023 Certificate Authority_. Its certificate request was signed by _Root 2024 Certificate Authority_ which means that leaf certs signed by _Intermediate 2023 Certificate Authority_ can be verified using two trust chains:

- leaf -> Intermediate 2023 Certificate Authority -> Root 2023 Certificate Authority
- leaf -> Cross-signed Intermediate 2024 Certificate Authority -> Root 2024 Certificate Authority

### Leaf Cert Signed by Intermediate 2023 Certificate Authority

This is the actual server certificate.

## Build

```
terraform init
terraform plan
terraform apply
```

If you don't change any variables, the module will output the following files:

```
test/local_test/test-key.pem
test/local_test/test-ca-2023.pem
test/local_test/test-ca-2024.pem
test/local_test/test-leaf.pem
test/local_test/test-int-2024.pem
test/local_test/test-crt.pem
test/local_test/test-int-2023.pem
```

You can change the contents of `test/local_test/test-crt.pem` (which is the bundle the ngninx server serves) by uncommenting blocks of code at the end of `tls.tf`.

## Start

```
cd test/local_test
docker build -t my-nginx . && docker run --name my-nginx -d -p 443:443 my-nginx
```

## Test

`ssl.go` is a test program written in go that performs a TLS handshake, and prints out the error on failure or the certificates on success. You might think "Why don't we just use openssl for this?" I'm glad you asked. [This bug](https://github.com/openssl/openssl/issues/18708) in openssl means that you can't use `openssl s_client` to handshake with a server that presents multiple intermediate CAs along with its leaf.

Use `ssl.go` like this:

`go run ../ssl.go localhost:443 [other-root.crt|test-ca-2023.pem|test-ca-2024.pem]`

## Stop
`docker stop my-nginx && docker rm my-nginx`

## Examples

Use these other examples to experiment with and verify TLS connections with various combinations of server cert bundle and root CA.

### Basic example

1. Use the `Server serves leaf and 2023 intermediate` Server Bundle Block in `tls.tf`
2. Connect with `ssl.go` using `test-ca-2023.pem`
3. TLS handshake succeeds.
4. Connect with `ssl.go` using `test-ca-2024.pem`
5. Connection fails because no trust chain can be built from the leaf to the root 2024 CA.

### Cross sign example

1. Use the `Server serves leaf, 2023 intermediate, and cross-signed 2024 intermediate` Server Bundle Block in `tls.tf`
2. Connect with `ssl.go` using `test-ca-2023.pem`
3. TLS handshake succeeds.
4. Connect with `ssl.go` using `test-ca-2024.pem`
5. TLS handshake succeeds because the SSL client can iteratively try each of the intermediates presented by the server, and finds a valid trust chain of `leaf -> test-int-2024 -> test-ca-2024.pem`


