#!/bin/bash

set -x
set -e

t=$(date +%s)
t=$(echo "$t * 1000" | bc)

# encodeURIComponent the access token
accessToken="U2FsdGVkX19UiHrIpRe%2BXArbuvY7tzNNp2T6ZgeJXo48eCTPc%2FceMEY3DT6oCSlaWBAPyBxupysO3OQcFcsvxU8OBLnq8WEoCPD86J%2FA09KP5UW2uCD4XhTkomdr3RhN"

userId="63a2b4f991a0a66ae2442354"
cronRunMins=10

url="https://supergroup.ai/api/3pa/sheetsCron?cronRunMins=$cronRunMins&loggedInUserId=$userId&accessToken=$accessToken&uid=$t"

echo $url

#wget -nv -O /home/gagandeep/cron_logs/sheets-sync-send-$t.log $url
# IMPORTANT:
# --tries=1 is important, because haproxy client/server timeout means connection will get dropped, and having wget retry can cause scheduled messages to be sent multiple times
# --method=POST is important because otherwise nginx treats the request as idempotent and retries
wget -d --method=POST --tries=1 --timeout=120 -nv -O- $url
