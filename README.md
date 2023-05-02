# dynv6 DDNS updater in a docker

Update IP on dynv6 periodically. Works with docker secrets. Will be built for the following targets in the future: `amd64`, `arm64` and `armv7`. Haven't gotten around to it yet.

Now using alpine:latest image for a small footprint. I know alpine:3.13 had an issue with `armv7`. Have not tested latest image on `armv7`. If you have issues, let me know. Will revert to alpine:3.12.

Only works for IPv6 at the moment, will add ipv4 support soon.

## Parameters / Environment Variables
| # | Parameter | Default | Notes | Description |
| - | --------- | ------- | ----- | ----------- |
| 1 | API_KEY | - | REQUIRED | Your dynv6 zone API Key/Token |
| 2 | ZONE | - | REQUIRED | The DNS zone/domain/hostname registered on dynv6 |
| 3 | RECORD_TYPE | AAAA | OPTIONAL | Record types supported AAAA (IPv6), A (IPv4) will be added soon |
| 4 | FREQUENCY | 5 | OPTIONAL | Frequency of IP updates on dynv6 (default - every 5 mins) |
