#!/bin/bash
# Fresh, deployed, publication-prepared database <name> (TESTING_GUIDE.md section 0): clone a per-tree template, or build it once.
# Target cluster: GXB_TEST_PGHOST/GXB_TEST_PGPORT, defaulting to the shared i853_dev cluster.
# usage: fresh_db.sh <name>
set -euo pipefail
. /home/akm/Chatgpt/EOL_Game/ops/testing/goenv.sh > /dev/null
H=${GXB_TEST_PGHOST:-$W/tmp/test-databases/i853_dev}
P=${GXB_TEST_PGPORT:-55853}
# Workers test before they commit, so the key covers uncommitted and untracked files as well as HEAD and migrations.
tree_state() {
  git rev-parse HEAD 2>/dev/null || echo unknown
  git diff HEAD 2>/dev/null
  git ls-files -z -o --exclude-standard 2>/dev/null | LC_ALL=C sort -z | xargs -0 -r sha1sum
  find migrations -type f -print0 | LC_ALL=C sort -z | xargs -0 sha1sum
}
TEMPLATE=tpl_$(tree_state | sha1sum | cut -c1-12)
TEMPLATES_KEPT=${GXB_TEST_TEMPLATES_KEPT:-4}
TEMPLATE_DSN="postgres://postgres@/$TEMPLATE?host=$H&port=$P"
DSN="postgres://postgres@/$1?host=$H&port=$P"
# --force terminates the database's sessions; the timeout keeps a stuck client from hanging the caller (audit A-008).
drop_target() { timeout 60 dropdb --force -h "$H" -p "$P" -U postgres --if-exists "$1" < /dev/null; }
# The migration/content/HEAD key changes when any of them changes, so a stale template is never reused.
exec 9>"$H/tpl.lock"
flock 9
if [ "$(psql -h "$H" -p "$P" -U postgres -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = '$TEMPLATE'")" != "1" ]; then
  drop_target "$TEMPLATE"
  createdb -h "$H" -p "$P" -U postgres "$TEMPLATE"
  goose -dir migrations postgres "$TEMPLATE_DSN" up > /dev/null
  GXB_POSTGRES_DSN=$TEMPLATE_DSN go run -tags postgres,river ./cmd/gxb-content-broadcast-deploy > /dev/null
  GXB_I7A9_DSN=$TEMPLATE_DSN GXB_I7A9_PREPARE_PROCESS=1 go test -count=1 -tags postgres,river -run '^(TestPreparePublicationProcess|TestPreparePublicationRiver)$' ./internal/integration/publication ./internal/adapters/river > /dev/null
  echo "FRESH_DB_TEMPLATE $TEMPLATE" >&2
  # Newest by oid first; older templates are dropped so the shared cluster does not fill up.
  psql -h "$H" -p "$P" -U postgres -d postgres -Atc "SELECT datname FROM pg_database WHERE datname ~ '^tpl_[0-9a-f]{12}$' ORDER BY oid DESC OFFSET $TEMPLATES_KEPT" |
    while read -r old; do drop_target "$old"; done
fi
# The clone stays under the lock so a concurrent build cannot prune the template mid-copy.
drop_target "$1"
createdb -h "$H" -p "$P" -U postgres -T "$TEMPLATE" "$1"
exec 9>&-
echo "FRESH_DB $DSN"
