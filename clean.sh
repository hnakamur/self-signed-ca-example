#!/bin/bash
ca_basename=${CA_BASENAME:-example-self-signed-ca}
rm -rf db tmp certs server-certs server-keys private ${ca_basename}.crt
