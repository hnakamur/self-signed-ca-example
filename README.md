# self-signed-ca-example

## Setup

```
mkdir db tmp certs
mkdir -m 700 private

touch db/index.txt
echo 'unique_subject = no' > db/index.txt.attr
echo '01' > db/serial

mkdir server-certs
mkdir -m 700 server-keys

touch certs/.gitkeep tmp/.gitkeep private/.gitkeep server-certs/.gitkeep server-keys/.gitkeep
```

Create the private key for self signed CA.

```
openssl genpkey -algorithm RSA -out private/example-self-signed-ca.key -pkeyopt rsa_keygen_bits:4096
```

View the private key for self signed CA.

```
openssl rsa -in private/example-self-signed-ca.key -text
```

Generate the CSR.

```
openssl req -new -config example-self-signed-ca.cnf -key private/example-self-signed-ca.key -out tmp/example-self-signed-ca.csr
```

View the CSR.

```
openssl req -in tmp/example-self-signed-ca.csr -text
```

Self sign the CA certificate (adjust `-days` appropriately).

```
openssl ca -batch -selfsign -config example-self-signed-ca.cnf -in tmp/example-self-signed-ca.csr -notext -out example-self-signed-ca.crt -extensions ca_ext -days 3660
```

View the certificate.

```
openssl x509 -in example-self-signed-ca.crt -text
```

Delete the CSR.

```
rm tmp/example-self-signed-ca.csr
```

## Create server key and certificate pair

```
./issue-server-certs-without-ip-address.sh $fqdn
```

or

```
./issue-server-certs-with-ip-address.sh $fqdn $ip_address
```
