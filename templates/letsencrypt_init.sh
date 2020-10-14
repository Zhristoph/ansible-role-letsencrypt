#!/bin/bash
set -eEuo pipefail

init() {
{% if letsEncryptMode == "live" %}
    letsEncryptModeOpt=""
{% else %}
    letsEncryptModeOpt="--test-cert"
{% endif %}
    letsEncryptOpts="-n --no-self-upgrade --standalone --rsa-key-size 4096 --email {{ email }} --agree-tos --no-eff-email ${letsEncryptModeOpt}"
    letsEncryptDomains="-d {{ fqdn }} {% for domain in letsEncryptMoreDomains -%} -d {{ domain }} {% endfor -%}"
    letsEncryptMoreCerts="{% for domain in letsEncryptMoreCerts -%} {{ domain }} {% endfor -%}"
}

runLetsEncrypt() {
    if [ ! -f /etc/letsencrypt/live/{{ fqdn }}/fullchain.pem ]; then
        /usr/bin/certbot certonly ${letsEncryptOpts} ${letsEncryptDomains}
    fi
    if [ ! -z "${letsEncryptMoreCerts}" ]; then
        for domain in ${letsEncryptMoreCerts}; do
            if [ ! -f /etc/letsencrypt/live/${domain}/fullchain.pem ]; then
                /usr/bin/certbot certonly ${letsEncryptOpts} -d ${domain}
            fi
        done
    fi
}

main() {
    init
    runLetsEncrypt
    /root/bin/letsencrypt-renew-hook.sh
}

main
