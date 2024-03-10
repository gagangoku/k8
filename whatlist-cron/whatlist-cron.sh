#!/bin/bash

set -x
set -e

echo "hi from whatlist-cron"
echo "attempt 1"
wget --timeout=120 -nv -O- http://superlist-backend.default.svc.cluster.local:3003/scheduled-messages/cron || true

sleep 30
echo "attempt 2"
wget --timeout=120 -nv -O- http://superlist-backend.default.svc.cluster.local:3003/scheduled-messages/cron || true
