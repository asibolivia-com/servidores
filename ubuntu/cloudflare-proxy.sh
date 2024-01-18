#!/bin/bash
# Source:
# https://www.cloudflare.com/ips
# https://support.cloudflare.com/hc/en-us/articles/200169166-How-do-I-whitelist-CloudFlare-s-IP-addresses-in-iptables-

# for ubuntu server > 22.0 nft tables
# Este comando utiliza nftables para añadir reglas a la tabla filter en la cadena input. La regla permite el tráfico TCP proveniente de las direcciones IP de Cloudflare en los puertos 80 y 443.
# Verificar si nft está instalado
if command -v nft > /dev/null; then
    for i in $(curl https://www.cloudflare.com/ips-v4); do nft add rule ip  filter input ip  saddr $i tcp dport {80, 443} accept done
    for i in $(curl https://www.cloudflare.com/ips-v6); do nft add rule ip6 filter input ip6 saddr $i tcp dport {80, 443} accept done
else
#this is old 
    for i in `curl https://www.cloudflare.com/ips-v4`; do iptables -I INPUT -p tcp -m multiport --dports http,https -s $i -j ACCEPT; done
    for i in `curl https://www.cloudflare.com/ips-v6`; do ip6tables -I INPUT -p tcp -m multiport --dports http,https -s $i -j ACCEPT; done
fi

# Verificar el directorio raíz del usuario actual
ROOT_DIR="/root"
if [ "$EUID" -eq 0 ]; then
    ROOT_DIR="/root"
else
    ROOT_DIR="/home/$(whoami)"
fi

REMOVE_SCRIPT="$ROOT_DIR/_cloudflare-proxy_remove.sh"
cat <<EOL > "$REMOVE_SCRIPT"
#!/bin/bash

# Contenido del script remove-cloudflare.sh
if command -v nft > /dev/null; then
    nft add rule ip filter input tcp dport {http, https} drop
    nft add rule ip6 filter input tcp dport {http, https} drop
else
#this is old 
    iptables -A INPUT -p tcp -m multiport --dports http,https -j DROP
    ip6tables -A INPUT -p tcp -m multiport --dports http,https -j DROP
fi
echo "Este es el script _cloudflare-proxy_remove.sh"
EOL

chmod +x "$REMOVE_SCRIPT"
