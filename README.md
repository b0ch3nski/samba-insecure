# samba-insecure
[![license](https://img.shields.io/github/license/b0ch3nski/samba-insecure)](LICENSE)
[![release](https://img.shields.io/github/v/release/b0ch3nski/samba-insecure)](https://github.com/b0ch3nski/samba-insecure/releases)
[![issues](https://img.shields.io/github/issues/b0ch3nski/samba-insecure)](https://github.com/b0ch3nski/samba-insecure/issues)

All-in-one Docker image with **Samba** and **Avahi** configured to provide simple anonymous file sharing.

## usage

```sh
docker run \
    --detach \
    --name="samba" \
    --restart unless-stopped \
    --network host \
    --volume "/tmp/smb:/storage:rw" \
    --env SMB_GROUP="$(id -gn)" \
    --env SMB_GID="$(id -g)" \
    --env SMB_USER="$(id -un)" \
    --env SMB_UID="$(id -u)" \
    --env ENABLE_AVAHI="true" \
    b0ch3nski/samba-insecure:latest
```

Alternatively try provided [docker-compose.yml](docker-compose.yml):
```sh
SMB_GROUP="$(id -gn)" SMB_GID="$(id -g)" SMB_USER="$(id -un)" SMB_UID="$(id -u)" docker compose up --detach
```

I recommend going through [init.sh](init.sh) for a better understanding how this works.

## disclaimer

This project was made for fun and learning purposes and shall not be used in real workloads. Use it with extra care and
only at your own risk.
