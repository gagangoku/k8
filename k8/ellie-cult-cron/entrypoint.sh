#!/bin/bash

set -x
set -e

#url="https://ellie.supergroup.ai/regenerateCultData?tablesToDump=DAU&gcsBucket=sg-ellie&numDays=60"
# url="http://ellie-server.default.svc.cluster.local:9009/healthz"
url="http://ellie-server.default.svc.cluster.local:9009/regenerateCultData?tablesToDump=DAU&gcsBucket=sg-ellie&numDays=60"

echo $url

# IMPORTANT:
# --tries=1 is important, because haproxy client/server timeout means connection will get dropped, and having wget retry can cause the url to be fetched multiple times
# --method=POST is important because otherwise nginx treats the request as idempotent and retries
wget -d --method=POST --tries=1 --timeout=1200 -nv -O- $url || true
