#!/bin/bash -xe

apt-get update

# Install monit
apt-get install -y monit

cat - > /etc/monit/conf.d/httpd <<'EOM'
set httpd port 2818
  use address localhost
  allow localhost
  allow admin:monit
EOM
systemctl enable monit

# Enable ip forwarding and nat
sysctl -w net.ipv4.ip_forward=1

# Make forwarding persistent.
sed -i= 's/^[# ]*net.ipv4.ip_forward=[[:digit:]]/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Install nginx for instance http health check
apt-get install -y nginx

ENABLE_SQUID="${squid_enabled}"

if [[ "$$ENABLE_SQUID" == "true" ]]; then
  apt-get install -y squid3

  cat - > /etc/squid/squid.conf <<'EOM'
${file("${squid_config == "" ? "${format("%s/config/squid.conf", module_path)}" : squid_config}")}
EOM

  systemctl reload squid
fi

ENABLE_L2TP="${l2tp_enabled}"

if [[ "$$ENABLE_L2TP" == "true" ]]; then
  apt-get install -y xl2tpd strongswan
  L2TP_KMS_LOCATION="${l2tp_kms_location}"
  L2TP_KMS_KEYRING="${l2tp_kms_keyring}"
  L2TP_KMS_KEY="${l2tp_kms_key}"

  L2TP_IP_CIPHER="${l2tp_ip_ciphertext}"
  L2TP_USERNAME_CIPHER="${l2tp_username_ciphertext}"
  L2TP_PASSWORD_CIPHER="${l2tp_password_ciphertext}"
  L2TP_PSK_CIPHER="${l2tp_psk_ciphertext}"
  L2TP_IP_RANGES="${l2tp_ip_ranges}"
  L2TP_GATEWAY="${l2tp_gateway}"

  # Fetch variables
  L2TP_IP=$$(echo $$L2TP_IP_CIPHER | base64 -d | gcloud kms decrypt --location $$L2TP_KMS_LOCATION \
	  --keyring $$L2TP_KMS_KEYRING \
	  --key $$L2TP_KMS_KEY \
	  --plaintext-file - \
	  --ciphertext-file -)
 
  L2TP_USERNAME=$$(echo $$L2TP_USERNAME_CIPHER | base64 -d | gcloud kms decrypt --location $$L2TP_KMS_LOCATION \
	  --keyring $$L2TP_KMS_KEYRING \
	  --key $$L2TP_KMS_KEY \
	  --plaintext-file - \
	  --ciphertext-file -)

  L2TP_PASSWORD=$$(echo $$L2TP_PASSWORD_CIPHER | base64 -d | gcloud kms decrypt --location $$L2TP_KMS_LOCATION \
	  --keyring $$L2TP_KMS_KEYRING \
	  --key $$L2TP_KMS_KEY \
	  --plaintext-file - \
	  --ciphertext-file -)

  L2TP_PSK=$$(echo $$L2TP_PSK_CIPHER | base64 -d | gcloud kms decrypt --location $$L2TP_KMS_LOCATION \
	  --keyring $$L2TP_KMS_KEYRING \
	  --key $$L2TP_KMS_KEY \
	  --plaintext-file - \
	  --ciphertext-file -)

  # Configure strongwswan
  cat - > /etc/ipsec.conf <<EOM
# ipsec.conf - strongSwan IPsec configuration file

# basic configuration

config setup
  # strictcrlpolicy=yes
  # uniqueids = no

# Add connections here.

# VPN connections

conn %default
  ikelifetime=60m
  keylife=20m
  rekeymargin=3m
  keyingtries=0
  keyexchange=ikev1
  authby=secret
  ike=3des-sha1-modp1024!
  esp=3des-sha1!

conn mainvpn
  keyexchange=ikev1
  left=%defaultroute
  keyingtries=0
  auto=start
  dpdaction=restart
  closeaction=restart
  authby=secret
  type=transport
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=$$L2TP_IP
EOM

  cat - > /etc/ipsec.secrets <<EOM
: PSK "$$L2TP_PSK"
EOM
  chmod 600 /etc/ipsec.secrets

  # Configure xl2tpd
  cat - > /etc/xl2tpd/xl2tpd.conf <<EOM
[lac mainvpn]
lns = $$L2TP_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOM

  cat - > /etc/ppp/options.l2tpd.client <<EOM
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
defaultroute
usepeerdns
connect-delay 5000
name $$L2TP_USERNAME
password $$L2TP_PASSWORD
EOM
chmod 600 /etc/ppp/options.l2tpd.client

cat - > /sbin/vpn_connect <<EOM
#!/bin/bash -e

CTRL=/var/run/xl2tpd/l2tp-control

mkdir -p /var/run/xl2tpd

echo "Restart services"
systemctl restart strongswan
systemctl restart xl2tpd

echo "Start IPSec connection"
set +e

IPSEC_CONNECTED=0
for i in \`seq 10\`; do
        echo "wait IPSec connection... \$$1"
        ipsec status mainvpn | grep -q '1 up' && IPSEC_CONNECTED=1 && break
        sleep 3
done
set -e
if [ \$$IPSEC_CONNECTED -eq 1 ]; then
        echo "IPSec connected!"
else
        echo "IPSec connection failed"
        exit 1
fi

echo "Start L2TP connection"
L2TP_CONNECTED=0
for i in \`seq 10\`; do
        if [ -e \$$CTRL ]; then
                for ii in \`seq 10\`; do
                        echo "L2TP connecting... \$$i-\$$ii"
                        echo "c mainvpn" > "\$$CTRL"
                        if [ -d "/sys/class/net/ppp0" ]; then
                                echo "L2TP: found ppp0"
                                L2TP_CONNECTED=1
                                break 2
                        fi
                        sleep 3
                done
        fi
        sleep 3
done

if [ \$$L2TP_CONNECTED -eq 1 ]; then
        echo "L2TP connected!"
else
        echo "L2TP connection failed"
        exit 1
fi

echo "Add routes: $$L2TP_IP_RANGES"
IP_RANGES="$$L2TP_IP_RANGES"
for r in \$${IP_RANGES[@]}; do
set -x
  ip route add \$$r dev ppp0
set +x
done

exit 0
EOM
chmod +x /sbin/vpn_connect

cat - > /sbin/vpn_disconnect <<EOM
#!/bin/bash -x
xl2tpd-control disconnect mainvpn
sleep 1
systemctl stop xl2tpd

ipsec down mainvpn
systemctl stop strongswan
EOM

cat - > /etc/monit/conf.d/vpn <<EOM
check host ppp0 with address $$L2TP_GATEWAY
   start program = "/sbin/vpn_connect"
   stop program = "/sbin/vpn_disconnect"
   if failed icmp type echo count 3 with timeout 15 seconds then restart
   if 5 restarts within 5 cycles then timeout
EOM

fi

systemctl reload monit
/sbin/vpn_connect
