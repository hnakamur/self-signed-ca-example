#!/bin/sh
set -eu
ca_basename=${CA_BASENAME:-example-self-signed-ca}

if [ $# -ne 1 ]; then
  echo "Usage: issue-server-cert-without-ip-address.sh server_fqdn"
  exit 1
fi

server_fqdn="$1"

key_file="server-keys/$server_fqdn.key"
csr_file="tmp/$server_fqdn.csr"
ext_file="tmp/$server_fqdn.ext"
cert_file="server-certs/$server_fqdn.crt"

openssl genpkey -algorithm RSA -out "$key_file" -pkeyopt rsa_keygen_bits:2048

openssl req -new -config ${ca_basename}.cnf -key "$key_file" -subj "/C=JP/ST=Osaka/L=Osaka City/O=Example self-signed CA organization/CN=$server_fqdn" -out "$csr_file"

cat <<EOF > "$ext_file"
authorityKeyIdentifier = keyid:always
basicConstraints = critical,CA:false
extendedKeyUsage = clientAuth,serverAuth
keyUsage = critical,digitalSignature,keyEncipherment
subjectKeyIdentifier = hash
subjectAltName = DNS:$server_fqdn
EOF

openssl ca -batch -config ${ca_basename}.cnf -in "$csr_file" -notext -out "$cert_file" -extfile "$ext_file" -days 3660

rm "$csr_file" "$ext_file"
