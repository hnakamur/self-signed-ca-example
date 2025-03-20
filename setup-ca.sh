#!/bin/bash
set -eu
ca_basename=${CA_BASENAME:-example-self-signed-ca}
days=${DAYS:-3660}

mkdir -p db tmp certs server-certs
mkdir -m 700 private server-keys

touch db/index.txt
echo 'unique_subject = no' > db/index.txt.attr
echo '01' > db/serial

openssl genpkey -algorithm RSA -out private/${ca_basename}.key -pkeyopt rsa_keygen_bits:4096

openssl rsa -in private/${ca_basename}.key -text

openssl req -new -config ${ca_basename}.cnf -key private/${ca_basename}.key -out tmp/${ca_basename}.csr

openssl req -in tmp/${ca_basename}.csr -text

openssl ca -batch -selfsign -config ${ca_basename}.cnf -in tmp/${ca_basename}.csr -notext -out ${ca_basename}.crt -extensions ca_ext -days ${days}

rm tmp/${ca_basename}.csr
