# dynv6 DDNS updater in a docker

Update IP on dynv6 periodically. Works with docker secrets. Will be built for the following targets in the future: `amd64`, `arm64` and `armv7`. Haven't gotten around to it yet.

Now using alpine:latest image for a small footprint. I know alpine:3.13 had an issue with `armv7`. Have not tested latest image on `armv7`. If you have issues, let me know. Will revert to alpine:3.12.

Now supports IPv6 and IPv4 record updates, but IPv6 needs additional settings. Please read [section](#using-ipv6) below.

Container packages available from Docker Hub and Github Container Registry (ghcr.io)
  - Docker Hub Image: `anujdatar/dynv6-ddns`
  - GHCR Image: `ghcr.io/anujdatar/dynv6-ddns`


## Parameters / Environment Variables
| # | Parameter | Default | Notes | Description |
| - | --------- | ------- | ----- | ----------- |
| 1 | API_KEY | - | REQUIRED | Your dynv6 zone API Key/Token |
| 2 | ZONE | - | REQUIRED | The DNS zone/domain/hostname registered on dynv6 |
| 3 | RECORD_TYPE | A | OPTIONAL | Record types supported A (IPv4) and AAAA (IPv6) |
| 4 | FREQUENCY | 5 | OPTIONAL | Frequency of IP updates on dynv6 (default - every 5 mins) |

---

## USAGE

### Docker cli
```bash
docker run \
    -e API_KEY="<your-dynv6-api-token>" \
    -e ZONE="<your-ddns-hostname>"  \
    -e RECORD_TYPE=A \
    --name dynv6-ddns \
    anujdatar/dynv6-ddns

```

### docker-compose

```yaml
version: "3"
services:
  cloudflare-ddns:
    image: anujdatar/dynv6-ddns
    container_name: dynv6-ddns
    restart: unless-stopped
    environment:
      - API_KEY="<your-dynv6-api-token>"
      - ZONE="<your-ddns-hostmane>"
      - RECORD_TYPE=A # OPTIONAL, default is A
      - FREQUENCY=1  # OPTIONAL, default is 5

```

### using docker-compose and docker secrets
In case you plan to commit your docker-compose files to repos and wish to keep tokens/domains secure
```yaml
version: "3"
services:
  cloudflare-ddns:
    image: anujdatar/dynv6-ddns
    container_name: dynv6-ddns
    restart: unless-stopped
    environment:
      - API_KEY_FILE=/run/secrets/api_key
      - ZONE=/run/secrets/zone
    secrets:
      - api_key
      - zone

secrets:
  api_key:
    external: true
  zone:
  	file: ./zone.txt

```

External secrets can be Docker Secrets created using the `docker secret create` command
```bash
echo <your-dynv6-api-token> | docker secret create api_key -

```

Your secret files should just be plain text strings containing zone/subdomain/email/token etc.

#### zone.txt
```txt
example.com
```
---

## Using IPv6
Docker by default only has IPv4 enabled. So containers can only access the web through IPv4. IPv6 traffic is not available by default. There are a few ways you can enable this, these are the quickest I found. I will link official docs where possible.

First you will have to allow IPv6 internet access to the docker subnet on your Host machine. Assuming the private Docker subnet we assign in the steps below is `fd00::/64`. You can use a different subnet if you wish. Or you may need to use a different subnet if you have multiple docker networks with IPv6 enabled.

> NOTE: If you use `ufw` on your system, you will need some additional settings. Please read [section](#ipv6-with-ufw)


```bash
ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
```
This setting is not persistent, and will not survive a reboot. To make it persistent

```bash
# install iptables-persistent and netfilter-persistent
sudo apt-get install iptables-persistent netfilter-persistent

# save you rules
sudo iptables-save > /etc/iptables/rules.v4
sudo ip6tables-save > /etc/iptables/rules.v6

# restart services
sudo systemctl restart netfilter-persistent

# if you need to restore backed-up rules
sudo iptables-restore < /etc/iptables/rules.v4
sudo ip6tables-restore < /etc/iptables/rules.v6
```
For more information on persistent rules or iptables on RPM based systems, refer to
[1](https://askubuntu.com/questions/1052919/iptables-reload-restart-on-ubuntu/1072948#1072948)
and [2](https://linuxconfig.org/how-to-make-iptables-rules-persistent-after-reboot-on-linux)

For more on IPv6 and docker you can check out this [medium](https://medium.com/@skleeschulte/how-to-enable-ipv6-for-docker-containers-on-ubuntu-18-04-c68394a219a2) article. I do not expose individual docker containers to internet via IPv6 directly, but the article goes over ways to do this. If you need it.

### 1. Enable IPv6 on the default bridge network
Source: [Docker Docs - IPv6](https://docs.docker.com/config/daemon/ipv6/)
1. Edit `etc/docker/daemon.json` and add the following
   ```json
    {
      "ipv6": true,
      "fixed-cidr-v6": "fd00::/64"
    }
   ```
2. Reload the docker config file
   ```bash
   systemctl reload docker
   # or restart the docker service
   systemctl restart docker
   ```
3. You can now start any container connected to the default bridge. You should have IPv6 access. To connect a docker-compose container to default bridge, add `network_mode: bridge` option to the service.

### 2. Create a new persistent network with IPv6 access
In case you want to keep your networks separate.
```bash
docker network create --subnet=172.16.2.0/24 --gateway=172.16.2.1 --ipv6 --subnet=fd00::/64 ipv6bridge
```
You can now connect your container to this network using `--network ipv6bridge`. Or in your `docker-compose.yml` file using
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options
    networks:
      - my-net

networks:
  my-net:
    external:
      name: ipv6bridge
```

or
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    external:
      name: ipv6bridge
```

### 3. Define the network in your `docker-compose` file
This will be a disposable network, and will be removed when you stop your application. This example changes the default network of all the services in the application. You can create a named network and assign it to services individually as well.

Source: [Docker Compose Networking](https://docs.docker.com/compose/networking/)
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: fd00::/64
```

## IPv6 with ufw
UFW seems to have an issue properly routing ipv6 traffic to docker networks. This is what worked for me after a lot of trial and error. Since most of it similar to the section above, I'll try keep it brief.

### 1. Enable IPv6 on the default bridge network
Assuming your default docker network interface is `docker0` (check using `ip a`), and you're still using the same `fd00::/64` subnet.

1. Edit `etc/docker/daemon.json` and add the following
   ```json
    {
      "ipv6": true,
      "fixed-cidr-v6": "fd00::/64"
    }
   ```
2. Reload the docker config file
   ```bash
   systemctl reload docker
   # or restart the docker service
   systemctl restart docker
   ```
3. Update `ufw` and `iptables` settings
   ```bash
   sudo ufw route allow in on docker0
   sudo ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
   sudo iptables -t mangle -A FORWARD -i docker0 -o end0 -j ACCEPT
   sudo iptables -t mangle -A FORWARD -i end0 -o docker0 -j ACCEPT

   # install iptables-persistent and netfilter-persistent
   sudo apt-get install iptables-persistent netfilter-persistent
   ```


### 2. Create a new persistent network with IPv6 access
In case you want to keep your networks separate. Assuming you're still using the same `fd00::/64` subnet. To keep things repeatable you might also want to assign a name to your new network interface instead of some default like `br-451d9eb3tes8`. I'll call it `ipv6-bridge`.

> NOTE: network interface name is different from the docker network name. you can check the name after you've created the network using `ip a`

```bash
docker network create --subnet=172.16.2.0/24 --gateway=172.16.2.1 --ipv6 --subnet=fd00::/64 --opt com.docker.network.bridge.name=ipv6-bridge ipv6bridge
```

Update `ufw` and `iptables` settings
```bash
sudo ufw route allow in on ipv6-bridge
sudo ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
sudo iptables -t mangle -A FORWARD -i ipv6-bridge -o end0 -j ACCEPT
sudo iptables -t mangle -A FORWARD -i end0 -o ipv6-bridge -j ACCEPT

# install iptables-persistent and netfilter-persistent
sudo apt-get install iptables-persistent netfilter-persistent
```

You can now connect your container to this network using `--network ipv6bridge`. Or in your `docker-compose.yml` file using

```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    external:
      name: ipv6bridge
```
### 3. Define the network in your `docker-compose` file
This will be a disposable network, and will be removed when you stop your application.

Again, assuming you use the subnet `fd00::/64` and use `ipv6-bridge` for the interface name.

Add `ufw` and `iptables` rules
```bash
sudo ufw route allow in on ipv6-bridge
sudo ip6tables -t nat -A POSTROUTING -s fd00::/64 -j MASQUERADE
sudo iptables -t mangle -A FORWARD -i ipv6-bridge -o end0 -j ACCEPT
sudo iptables -t mangle -A FORWARD -i end0 -o ipv6-bridge -j ACCEPT

# install iptables-persistent and netfilter-persistent
sudo apt-get install iptables-persistent netfilter-persistent
```

Source: [Docker Compose Networking](https://docs.docker.com/compose/networking/)
```yaml
services:
  your-service-name:
    image: xyz
    other-options: options

networks:
  default:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: fd00::/64
    driver_opts:
      com.docker.network.bridge.name: ipv6-bridge
```
