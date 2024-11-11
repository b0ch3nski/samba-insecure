#!/bin/sh
set -eo pipefail

AVAHI_CONF="/etc/avahi/avahi-daemon.conf"
SMB_CONF="/etc/samba/smb.conf"

: "${SMB_GROUP:=samba}"
: "${SMB_GID:=1234}"
: "${SMB_USER:=samba}"
: "${SMB_UID:=1234}"
: "${SMB_PATH:=/storage}"

: "${WORKGROUP:=123}"
: "${NETBIOS_NAME:=docker}"
: "${SHARE_NAME:=share}"

trap 'echo "==> Exit signal received - goodbye!"; exit 0' INT TERM

echo "==> Creating '${SMB_USER}:${SMB_GROUP}' (${SMB_UID}:${SMB_GID})"
addgroup -g "${SMB_GID}" "${SMB_GROUP}" || true
adduser -D -h "${SMB_PATH}" -G "${SMB_GROUP}" -u "${SMB_UID}" -s /sbin/nologin "${SMB_USER}" || true
chmod -v 775 "${SMB_PATH}"

cat << EOF > "${SMB_CONF}"
[global]
   workgroup = ${WORKGROUP}
   netbios name = ${NETBIOS_NAME}
   server string = Samba server on Docker
   server role = standalone server
   use sendfile = yes
   domain master = no
   security = user
   map to guest = Bad User
   guest account = ${SMB_USER}

# mdns & nmbd
   multicast dns register = no
   wins support = yes
   wins proxy = no
   dns proxy = no
   local master = no
   preferred master = no

# disable printing
   load printers = no
   disable spoolss = yes
   show add printer wizard = no

# enable symlinks
   follow symlinks = yes
   wide links = yes
   allow insecure wide links = yes

# protocol hacks
   lanman auth = yes
   ntlm auth = yes
   server min protocol = ${MIN_PROTOCOL:-NT1}
   client min protocol = ${MIN_PROTOCOL:-NT1}
   client lanman auth = yes
   client ntlmv2 auth = no
   client use spnego = no

# fix permissions
   force user = ${SMB_USER}
   force group = ${SMB_GROUP}
   force create mode = 0664
   force directory mode = 0775

[${SHARE_NAME}]
   path = ${SMB_PATH}
   dos filemode = yes
   hide dot files = no
   writable = yes
   browseable = yes
   guest ok = yes
   guest only = yes
EOF

echo -e "==> Starting Samba with configuration:\n$(cat ${SMB_CONF})"
smbd --configfile="${SMB_CONF}" --foreground --debug-stdout --debuglevel="${DEBUG:-1}" --no-process-group &
while ! nc -z 127.0.0.1 445; do sleep 1; done
echo "==> SMBD started"

nmbd --configfile="${SMB_CONF}" --foreground --debug-stdout --debuglevel="${DEBUG:-1}" --no-process-group &
while ! nc -zu 127.0.0.1 137; do sleep 1; done
echo "==> NMBD started"

if [ "${ENABLE_AVAHI}" = "true" ]; then
    cat << EOF > /etc/avahi/services/samba.service
<?xml version="1.0" standalone="no"?>
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<service-group>
  <name replace-wildcards="yes">%h samba</name>
  <service>
    <type>_smb._tcp</type>
    <port>445</port>
  </service>
</service-group>
EOF
    cat << EOF > "${AVAHI_CONF}"
[server]
host-name=${NETBIOS_NAME}
enable-dbus=no
EOF
    echo -e "==> Starting Avahi with configuration:\n$(cat ${AVAHI_CONF})"
    avahi-daemon --file="${AVAHI_CONF}" --no-rlimits --no-drop-root --no-chroot &
    while ! nc -zu 127.0.0.1 5353; do sleep 1; done
    echo "==> Avahi started"
fi

while true; do
    smbclient "//${NETBIOS_NAME}/${SHARE_NAME}" \
        --command="recurse;ls" \
        --timeout="${HEALTHCHECK_TIMEOUT:-3}" \
        --configfile="${SMB_CONF}" \
        --name-resolve="wins" \
        --workgroup="${WORKGROUP}" \
        --user="%" --no-pass \
        2>/dev/null | grep -q "blocks available"
    sleep ${HEALTHCHECK_INTERVAL:-60} &
    wait $!
done
