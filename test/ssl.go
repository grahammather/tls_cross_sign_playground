package main

import (
    "crypto/tls"
    "crypto/x509"
    "encoding/pem"
    "fmt"
    "io/ioutil"
    "log"
    "os"
)

func main() {
    if len(os.Args) != 3 {
        log.Fatalf("Usage: %s <server-address> <root-ca-file>\n", os.Args[0])
    }

    serverAddr := os.Args[1]
    rootCAFile := os.Args[2]

    // Load the root CA
    rootCA, err := ioutil.ReadFile(rootCAFile)
    if err != nil {
        log.Fatalf("Failed to read root CA file: %v\n", err)
    }

    rootCAs := x509.NewCertPool()
    if ok := rootCAs.AppendCertsFromPEM(rootCA); !ok {
        log.Fatalf("Failed to append root CA from file: %s\n", rootCAFile)
    }

    // Configure TLS to skip built-in verification and use custom verification
    conf := &tls.Config{
        InsecureSkipVerify: true, // Skip the built-in verification
        VerifyPeerCertificate: func(rawCerts [][]byte, verifiedChains [][]*x509.Certificate) error {
            // Convert raw certificates to x509.Certificate
            certs := make([]*x509.Certificate, len(rawCerts))
            for i, asn1Data := range rawCerts {
                cert, err := x509.ParseCertificate(asn1Data)
                if err != nil {
                    return err
                }
                certs[i] = cert
            }

            // Use the first certificate as leaf
            leafCert := certs[0]

            // Create a new CertPool and add the intermediate certificates
            intermediates := x509.NewCertPool()
            for _, ic := range certs[1:] {
                intermediates.AddCert(ic)
            }

            // Manually verify the certificate chain
            verifyOpts := x509.VerifyOptions{
                Roots:         rootCAs,
                Intermediates: intermediates,
                KeyUsages:     []x509.ExtKeyUsage{x509.ExtKeyUsageAny},
            }

            // Ignoring the server name verification by not setting DNSName
            if _, err := leafCert.Verify(verifyOpts); err != nil {
                return fmt.Errorf("failed to verify certificate chain: %v", err)
            }
            return nil
        },
    }

    // Establish a connection to the server
    conn, err := tls.Dial("tcp", serverAddr, conf)
    if err != nil {
        fmt.Printf("TLS handshake failed: %v\n", err)
        return
    }
    defer conn.Close()

    fmt.Printf("Connected to %s\n", serverAddr)
    fmt.Println("TLS handshake completed successfully")

    // Get the ConnectionState for access to TLS details
    connState := conn.ConnectionState()

    // Print the server certificates
    for i, cert := range connState.PeerCertificates {
        fmt.Printf("Certificate #%d:\n", i+1)
        printCertificate(cert)
    }
}

func printCertificate(cert *x509.Certificate) {
    // Print details about the certificate
    fmt.Printf("\tIssuer: %s\n", cert.Issuer)
    fmt.Printf("\tSubject: %s\n", cert.Subject)
    fmt.Printf("\tValid from %s to %s\n", cert.NotBefore, cert.NotAfter)

    // Print the PEM encoded certificate
    pemData := pem.EncodeToMemory(&pem.Block{
        Type:  "CERTIFICATE",
        Bytes: cert.Raw,
    })
    fmt.Println("\tPEM Encoded Certificate:")
    fmt.Printf("%s\n", pemData)
}
