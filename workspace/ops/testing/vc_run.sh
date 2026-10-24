#!/bin/bash
# One virtual-client run: starts gxb-api on 127.0.0.1:18853 against database $VCDB (default vc), boots the stock client to
# MainScene, optionally plays $SCENARIO, writes tmp/virtualclient/runs/<run-name>/{api.log,client.log,report.json}.
# Does NOT build binaries (see TESTING_GUIDE.md). Env: VC_ROOT VCDB LIMIT TAPS UPDATE_TREE SCENARIO COVERAGE REPORTS.
# usage: vc_run.sh <run-name>
W=/home/akm/Chatgpt/EOL_Game; V=${VC_ROOT:-$W/tmp/virtualclient}
RUN=$V/runs/$1; rm -rf $RUN; mkdir -p $RUN/device
DSN="postgres://postgres@/${VCDB:-vc}?host=$W/tmp/test-databases/i853_dev&port=55853"
ORIGIN=http://127.0.0.1:18853
export GXB_CREDENTIAL_DIGEST_SECRET=vc-fixture-digest-key-000000001
env GXB_POSTGRES_DSN="$DSN" GXB_HTTP_ADDR=127.0.0.1:18853 GXB_PUBLIC_ENGINE_URL=$ORIGIN/engine GXB_CLIENT_LOG_URL=$ORIGIN/client-log \
  GXB_REALTIME_PUBLIC_HOST=127.0.0.1 GXB_REALTIME_PUBLIC_PORT=18854 GXB_GAMEPLAY_BEARER_SECRET=vc-fixture-bearer-key-000000001 \
  GXB_REDEEM_DIGEST_SECRET=vc-fixture-redeem-key-000000001 GXB_DERIVATION_KEY_ID=vc-native GXB_PROFILE_MEDIA_ROOT=$RUN/private-media \
  GXB_PROFILE_MEDIA_PUBLIC_ORIGIN=$ORIGIN GXB_COMBAT_ENTROPY_KEYS=vc1=7663000000000000000000000000000000000000000000000000000000000001 GXB_COMBAT_ENTROPY_KEY_CURRENT=vc1 $V/bin/gxb-api > $RUN/api.log 2>&1 &
API=$!
for i in $(seq 300); do curl -s -o /dev/null $ORIGIN/client-log && break; sleep 0.2; done
$V/bin/gxb-virtual-client -source $V/src_64 -assets $V/apk -device $RUN/device -origin $ORIGIN -database "$DSN" -limit ${LIMIT:-120s} ${TAPS:+-taps "$TAPS"} ${UPDATE_TREE:+-update-tree "$UPDATE_TREE"} ${SCENARIO:+-scenario "$SCENARIO"} -report $RUN/report.json > $RUN/client.log 2>&1
echo client=$?
[ -n "$COVERAGE" ] && $V/bin/gxb-mid-coverage -mid-table $V/src_64/app/common/network/mid.lua -engine $ORIGIN/engine -database "$DSN" ${REPORTS:+-reports "$REPORTS"} -out $RUN/MID_COVERAGE.json
kill $API; wait $API 2>/dev/null
