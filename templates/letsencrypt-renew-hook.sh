#!/bin/bash
set -eEuo pipefail

init(){
    mainDomain={{ fqdn }}
    letsEncryptDir="/etc/letsencrypt/live/"
    letsEncryptDomains=$(/usr/bin/find ${letsEncryptDir} -mindepth 1 -maxdepth 1 -type d -printf "%f\n")
    fullChainKeyDir="/etc/ssl/private"
    defaultDomainPem="${fullChainKeyDir}/00_default.pem"
    mainDomainPem="${fullChainKeyDir}/${mainDomain}.pem"
}

createFullChain(){
    for domain in ${letsEncryptDomains}; do
        /bin/cat "${letsEncryptDir}/${domain}/fullchain.pem" > "${fullChainKeyDir}/${domain}.pem"
        /bin/cat "${letsEncryptDir}/${domain}/privkey.pem" >> "${fullChainKeyDir}/${domain}.pem"
        /bin/chown root:root "${fullChainKeyDir}/${domain}.pem"
        /bin/chmod o-rwx "${fullChainKeyDir}/${domain}.pem"
    done
}

main(){
    init
    createFullChain
    if [ ! -L "${defaultDomainPem}" ] || [ ! -e "${defaultDomainPem}" ] ; then
        /bin/ln -sf "${mainDomainPem}" "${defaultDomainPem}"
        /bin/ln -sf "${mainDomainPem}.ocsp" "${defaultDomainPem}.ocsp"
    fi
    if /bin/systemctl status postfix > /dev/null 2>&1; then
        /bin/systemctl reload postfix > /dev/urandom 2>&1;
    fi
    if /bin/systemctl status dovecot > /dev/null 2>&1; then
        /bin/systemctl reload dovecot > /dev/urandom 2>&1;
    fi
}

main
