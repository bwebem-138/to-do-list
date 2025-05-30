# Create SSL directory if it doesn't exist
New-Item -ItemType Directory -Force -Path .\ssl

# Load environment variables
$envContent = Get-Content .env
foreach ($line in $envContent) {
    if ($line -match '(.+)=(.+)') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}

# Generate self-signed certificate
$cert = New-SelfSignedCertificate `
    -Subject "CN=$env:CERT_DOMAIN" `
    -DnsName "$env:CERT_DOMAIN" `
    -KeyAlgorithm RSA `
    -KeyLength 2048 `
    -NotBefore (Get-Date) `
    -NotAfter (Get-Date).AddYears(1) `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -FriendlyName $env:CERT_FRIENDLY_NAME `
    -HashAlgorithm SHA256 `
    -KeyUsage DigitalSignature, KeyEncipherment, DataEncipherment `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.1")

# Export certificate and private key
$pwd = ConvertTo-SecureString -String $env:CERT_PASSWORD -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath ".\ssl\certificate.pfx" -Password $pwd
openssl pkcs12 -in ".\ssl\certificate.pfx" -out ".\ssl\cert.pem" -nodes
openssl pkcs12 -in ".\ssl\certificate.pfx" -out ".\ssl\key.pem" -nodes -nocerts