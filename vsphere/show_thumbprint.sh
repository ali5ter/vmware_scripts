#!/usr/bin/env bash
# @file show_thumbprint
# @author Alister Lewis-Bowen

# @see http://www.virtuallyghetto.com/2012/04/extracting-ssl-thumbprint-from-esxi.html

HOST=$1

[ -z "$HOST" ] && {
    echo
    read -rp "Address of the vCenter Server or ESXi host: " HOST
}

echo -n | openssl s_client -connect "$HOST":443 2>/dev/null | openssl x509 -noout -fingerprint -sha1