#!/bin/sh
set -eu

default_ca_name="${CA_NAME:-}"

usage() {
  cat >&2 <<EOF
Usage: $0 <command> [options]

This is a script for seting up your self-signed certificate authority, and
for issuing server certificates using it.

Commands:
  setup
  issue-cert
  clean
EOF
  exit 2
}

usage_setup() {
  cat >&2 <<EOF
Usage: $0 setup [options]

Options:
  -d, --days NUMBER     The number of days to certify the certificate for.
  --ca STRING      The file basename for your Certificate Authority.
EOF
  exit 2
}

setup() {
  days=3660
  ca_name="$default_ca_name"
  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--days)
        if [ $# -lt 2 ]; then
          usage_setup
        fi
        days="$2"
        shift 2
        ;;
      --ca)
        if [ $# -lt 2 ]; then
          usage_setup
        fi
        ca_name="$2"
        shift 2
        ;;
      *)
      usage_setup
        ;;
    esac
  done

  ca_conf_file="$ca_name.cnf"
  if [ ! -f "$ca_conf_file" ]; then
    echo "Please create the config file for CA with filename: $ca_conf_file" >&2
    exit 1
  fi

  mkdir db tmp certs server-certs
  mkdir -m 700 private server-keys

  touch db/index.txt
  echo 'unique_subject = no' > db/index.txt.attr
  echo '01' > db/serial

  openssl genpkey -algorithm RSA -out private/${ca_name}.key -pkeyopt rsa_keygen_bits:4096
  openssl rsa -in private/${ca_name}.key -text
  openssl req -new -config ${ca_name}.cnf -key private/${ca_name}.key -out tmp/${ca_name}.csr
  openssl req -in tmp/${ca_name}.csr -text
  openssl ca -batch -selfsign -config ${ca_name}.cnf -in tmp/${ca_name}.csr -notext -out ${ca_name}.crt -extensions ca_ext -days ${days}
  rm tmp/${ca_name}.csr
}

usage_issue_cert() {
  cat >&2 <<EOF
Usage: $0 issue-cert [options]

Issue a server certificate.

Options:
  --ca STRING           The file basename for your Certificate Authority.
  --fqdn STRING         The fully qualified domain name for the server certificate.
  --ip STRING           The ip address for the server certificate (optional).
  -d, --days NUMBER     The number of days to certify the certificate for (default: 366).
EOF
  exit 2
}

issue_cert() {
  days=366
  ca_name="$default_ca_name"
  server_fqdn=""
  server_ipaddr=""
  subject=""
  country="JP"

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--days)
        if [ $# -lt 2 ]; then
          usage_issue_cert
        fi
        days="$2"
        shift 2
        ;;
      --ca)
        if [ $# -lt 2 ]; then
          usage_issue_cert
        fi
        ca_name="$2"
        shift 2
        ;;
      --fqdn)
        if [ $# -lt 2 ]; then
          usage_issue_cert
        fi
        server_fqdn="$2"
        shift 2
        ;;
      --ip)
        if [ $# -lt 2 ]; then
          usage_issue_cert
        fi
        server_ipaddr="$2"
        shift 2
        ;;
      --country)
        if [ $# -lt 2 ]; then
          usage_issue_cert
        fi
        country="$2"
        shift 2
        ;;
      *)
      usage_issue_cert
        ;;
    esac
  done

  if [ ! -f "$ca_name.crt" ]; then
    cat >&2 <<EOF
The CA certificate file ($ca_name.crt) does not exist.
Please set up $ca_name Certificate Authority with $0 setup command.
EOF
    exit 1
  fi

  key_file="server-keys/$server_fqdn.key"
  csr_file="tmp/$server_fqdn.csr"
  ext_file="tmp/$server_fqdn.ext"
  cert_file="server-certs/$server_fqdn.crt"

  openssl genpkey -algorithm RSA -out "$key_file" -pkeyopt rsa_keygen_bits:2048

  if [ "$subject" = "" ]; then
    subject="/CN=$server_fqdn/"
  fi

  openssl req -new -config ${ca_name}.cnf -key "$key_file" -subj "$subject" -out "$csr_file"

  if [ "$server_ipaddr" = "" ]; then
    cat <<EOF > "$ext_file"
authorityKeyIdentifier = keyid:always
basicConstraints = critical,CA:false
extendedKeyUsage = clientAuth,serverAuth
keyUsage = critical,digitalSignature,keyEncipherment
subjectKeyIdentifier = hash
subjectAltName = DNS:$server_fqdn
EOF
  else
    cat <<EOF > "$ext_file"
authorityKeyIdentifier = keyid:always
basicConstraints = critical,CA:false
extendedKeyUsage = clientAuth,serverAuth
keyUsage = critical,digitalSignature,keyEncipherment
subjectKeyIdentifier = hash
subjectAltName = DNS:$server_fqdn, IP:$server_ipaddr
EOF
  fi

  openssl ca -batch -config ${ca_name}.cnf -in "$csr_file" -notext -out "$cert_file" -extfile "$ext_file" -days $days

  rm "$csr_file" "$ext_file"
}

usage_clean() {
  cat >&2 <<EOF
Usage: $0 clean [options]

Delete all files for the specified certificate authority.

Options:
  --ca STRING      The file basename for your Certificate Authority.
EOF
  exit 2
}

clean() {
  ca_name="$default_ca_name"

  while [ $# -gt 0 ]; do
    case "$1" in
      --ca)
        if [ $# -lt 2 ]; then
          usage_clean
        fi
        ca_name="$2"
        shift 2
        ;;
      *)
      usage_clean
        ;;
    esac
  done

  if [ "$ca_name" = "" ]; then
    >&2 echo "Please specify CA name to delete."
    exit 1
  fi

  read -p "Do you really want to delete all files for CA $ca_name? (yes/no) " answer
  if [ "$answer" = "yes" ]; then
    rm -rf db tmp certs server-certs server-keys private ${ca_name}.crt
    >&2 echo "Deleted all files for CA $ca_name."
  fi
}

if [ $# -lt 1 ]; then
  usage
fi

command=$1
shift

case "$command" in
setup)
  setup "$@"
  ;;
issue-cert)
  issue_cert "$@"
  ;;
clean)
  clean "$@"
  ;;
*)
  usage
  ;;
esac
