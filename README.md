# self-signed-ca-example

## Set up

Edit my-ca.cnf for your self-signed Certificate Authority.

```
./my-ca.cnf setup --ca my-ca [--days 3660]
```

## Create server key and certificate pair

Issue a server key and certificate pair with a FQDN, or with a FQDN and an IP address.

```
./my-ca.cnf issue-cert --ca my-ca --fqdn your-server1.example.com [--ip 192.0.2.1] [--days 366]
```

## Clean up

Delete all files for your Certificate Authority and issued certificate and key pair files.

```
./my-ca.cnf clean --ca my-ca
```
