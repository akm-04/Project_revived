//go:build postgres

package publicationstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/publicationstore"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestPayloadVersionRoundTripPublicationStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2C_BATCH16_DSN")
	if dsn == "" {
		t.Fatal("required GXB_R8_2C_BATCH16_DSN for a migrated test database is missing")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	setID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	startsAt := time.Date(2026, 11, 16, 2, 0, 0, 123456000, time.UTC)
	input := pub.Set{
		ID:       setID,
		Family:   pub.Announcement,
		ServerID: 0,
		StartsAt: startsAt,
		Items:    []pub.Item{{Announcement: &pub.Section{Title: "Golden", Contents: []string{"line"}, URL: "http://golden"}}},
	}
	written, digest, err := input.Canonical()
	if err != nil {
		t.Fatalf("canonical fixture: %v", err)
	}
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err := (publicationstore.Store{}).InstallTx(ctx, transaction, written, digest); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var storedText string
	var version int16
	if err := pool.Raw().QueryRow(ctx, `SELECT payload::text,payload_version FROM publication_items WHERE set_id=$1 ORDER BY position LIMIT 1`, setID.String()).Scan(&storedText, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("payload_version=%d want=%d", version, payload.Current)
	}
	marshalled, err := json.Marshal(written.Items[0])
	if err != nil {
		t.Fatal(err)
	}
	var expectedText string
	if err := pool.Raw().QueryRow(ctx, `SELECT ($1::jsonb)::text`, string(marshalled)).Scan(&expectedText); err != nil {
		t.Fatal(err)
	}
	if storedText != expectedText {
		t.Fatalf("stored payload=%s want json.Marshal=%s", storedText, expectedText)
	}
	var decoded pub.Item
	if err := payload.Decode("publication_items", version, []byte(storedText), &decoded); err != nil {
		t.Fatalf("strict decode: %v", err)
	}
	if !reflect.DeepEqual(decoded, written.Items[0]) {
		t.Fatalf("decoded=%#v want=%#v", decoded, written.Items[0])
	}
	read, visible, err := (publicationstore.Store{}).SelectTx(ctx, pool, pub.Announcement, 0, startsAt.Add(time.Hour))
	if err != nil || !visible || read.ID != written.ID || read.Family != written.Family || read.ServerID != written.ServerID || !read.StartsAt.Equal(written.StartsAt) || read.EndsAt != nil || !reflect.DeepEqual(read.Items, written.Items) {
		t.Fatalf("SelectTx visible=%v err=%v read=%#v want=%#v", visible, err, read, written)
	}
}
