#!/bin/bash
# Fresh load-test database <name> on the shared i853_dev cluster (TESTING_GUIDE.md section 0); drops it first.
# usage: fresh_load_db.sh <load_name>
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
DIR=$(cd "$(dirname "$0")/../.." && pwd)
export GXB_BACKEND=${GXB_BACKEND:-$DIR}
. "$W/ops/testing/goenv.sh" > /dev/null
H=$W/tmp/test-databases/i853_dev
DSN="postgres://postgres@/$1?host=$H&port=55853"
dropdb --force -h "$H" -p 55853 -U postgres --if-exists "$1" < /dev/null
createdb -h "$H" -p 55853 -U postgres "$1"
goose -dir migrations postgres "$DSN" up > /dev/null
GXB_POSTGRES_DSN=$DSN go run -tags postgres,river ./cmd/gxb-content-broadcast-deploy 2>&1 | tail -1
GXB_I7A9_DSN=$DSN GXB_I7A9_PREPARE_PROCESS=1 go test -count=1 -tags postgres,river -run '^(TestPreparePublicationProcess|TestPreparePublicationRiver)$' ./internal/integration/publication ./internal/adapters/river > /dev/null
echo "FRESH_LOAD_DB $DSN"
