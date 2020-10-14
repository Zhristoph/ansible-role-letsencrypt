#!/bin/bash
set -eEuo pipefail

init(){
    fullChainKeyDir="/etc/ssl/private"
    letsEncryptDir="/etc/letsencrypt/live/"
    letsEncryptDomains=$(/usr/bin/find ${letsEncryptDir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
}

createOCSP(){
    # Get an OSCP response from the certificates OCSP issuer for use
    # with HAProxy
    for domain in ${letsEncryptDomains}; do
        # Get the OCSP URL from the certificate
        ocsp_url=$(/usr/bin/openssl x509 -noout -ocsp_uri -in "${letsEncryptDir}/${domain}/cert.pem")
        # Request the OCSP response from the issuer and store it
        /usr/bin/openssl ocsp \
            -timeout 120 \
            -issuer "${letsEncryptDir}/${domain}/chain.pem" \
            -cert "${letsEncryptDir}/${domain}/cert.pem" \
            -url "${ocsp_url}" \
            -respout "${fullChainKeyDir}/${domain}.pem.ocsp" > /dev/urandom 2>&1
    done
}

renewLetsEncrypt(){
    if /bin/systemctl status apache2 > /dev/urandom 2>&1; then
        /root/letsencrypt/letsencrypt-auto renew -q -n --no-self-upgrade --standalone --renew-hook /root/bin/letsencrypt-renew-hook.sh --pre-hook "/bin/systemctl stop apache2" --post-hook "/bin/systemctl start apache2" > /dev/urandom
    elif /bin/systemctl status haproxy > /dev/urandom 2>&1; then
        /root/letsencrypt/letsencrypt-auto renew -q -n --no-self-upgrade --standalone --renew-hook /root/bin/letsencrypt-renew-hook.sh --pre-hook "/bin/systemctl stop haproxy" --post-hook "/bin/systemctl start haproxy" > /dev/urandom
    else
        /root/letsencrypt/letsencrypt-auto renew -q -n --no-self-upgrade --standalone --renew-hook /root/bin/letsencrypt-renew-hook.sh > /dev/urandom
    fi
}

main(){
    init
    renewLetsEncrypt
    if /bin/systemctl status haproxy > /dev/urandom 2>&1; then
        createOCSP
        /bin/systemctl reload haproxy > /dev/urandom 2>&1;
    fi
}

main
