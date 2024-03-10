#!/bin/bash

set -x
set -e

echo "hi from whatlist-cron"
wget --timeout=120 -nv -O- http://superlist-backend.default.svc.cluster.local:3003/scheduled-messages/cron || true
# sleep 5
