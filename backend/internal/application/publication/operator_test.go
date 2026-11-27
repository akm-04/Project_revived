package publication

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fakePublicationStore struct {
	installed []pub.Set
	digests   []string
	selects   map[string]pub.Set
	visible   bool
}

func (fake *fakePublicationStore) InstallTx(_ context.Context, _ tx.Tx, set pub.Set, digest string) error {
	fake.installed = append(fake.installed, set)
	fake.digests = append(fake.digests, digest)
	return nil
}
func (fake *fakePublicationStore) SelectTx(_ context.Context, _ tx.Queryer, family string, _ identity.LogicalServerID, _ time.Time) (pub.Set, bool, error) {
	set, found := fake.selects[family]
	return set, found && fake.visible, nil
}
func (fake *fakePublicationStore) MarkerTx(context.Context, tx.Queryer, identity.PlayerID, ids.UUID) (bool, error) {
	return false, nil
}
func (fake *fakePublicationStore) LockMarkerTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID) error {
	return nil
}
func (fake *fakePublicationStore) MarkTx(context.Context, tx.Tx, identity.PlayerID, ids.UUID, time.Time) error {
	return nil
}

type publicationTx struct{}

func (publicationTx) QueryRow(context.Context, string, ...any) tx.Row {
	return publicationRow{err: errors.New("unexpected query")}
}
func (publicationTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return publicationTag(1), nil
}
func (publicationTx) Commit(context.Context) error   { return nil }
func (publicationTx) Rollback(context.Context) error { return nil }

type publicationRow struct{ err error }

func (row publicationRow) Scan(...any) error { return row.err }

type publicationTag int64

func (tag publicationTag) RowsAffected() int64 { return int64(tag) }

type publicationRunner struct{}

func (publicationRunner) Begin(context.Context, tx.Options) (tx.Tx, error) {
	return publicationTx{}, nil
}

func fixedUUID(t *testing.T, text string) ids.UUID {
	t.Helper()
	value, err := ids.ParseUUID(text)
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func TestInstallBuildsTheFamilyItemsAndCanonicalDigest(t *testing.T) {
	store := &fakePublicationStore{}
	at := time.Date(2026, 11, 22, 10, 0, 0, 0, time.UTC)
	commands := OperatorCommands{Store: store, Clock: func() time.Time { return at }, NewUUID: func() (ids.UUID, error) { return fixedUUID(t, "11111111-1111-1111-1111-111111111111"), nil }}
	payload := json.RawMessage(`{"family":"picture","server_id":2,"pictures":[{"weight":1.5,"pic":"http://example/p.png","small_pic":""}]}`)
	command, err := operator.NewCommand("publication.install", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "test", SemanticKey: "k1"}, payload)
	if err != nil {
		t.Fatal(err)
	}
	result, err := commands.installHandler(context.Background(), tx.Scope{Tx: publicationTx{}}, command)
	if err != nil {
		t.Fatal(err)
	}
	if len(store.installed) != 1 || store.digests[0] == "" {
		t.Fatalf("installed = %+v digests = %v", store.installed, store.digests)
	}
	set := store.installed[0]
	if set.Family != pub.Picture || set.ServerID != 2 || len(set.Items) != 1 || set.Items[0].Picture == nil || set.Items[0].Picture.Weight != 1.5 {
		t.Fatalf("set = %+v", set)
	}
	view, ok := result.(FamilyView)
	if !ok || !view.Visible || view.SetID != "11111111-1111-1111-1111-111111111111" {
		t.Fatalf("result = %+v", result)
	}
}

func TestInstallRefusesTheWrongItemShapeForTheFamily(t *testing.T) {
	store := &fakePublicationStore{}
	commands := OperatorCommands{Store: store}
	payload := json.RawMessage(`{"family":"announcement","pictures":[{"weight":1,"pic":"http://example/p.png"}]}`)
	command, err := operator.NewCommand("publication.install", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "test", SemanticKey: "k2"}, payload)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := commands.installHandler(context.Background(), tx.Scope{Tx: publicationTx{}}, command); err == nil {
		t.Fatal("a picture payload was accepted as the login notice")
	}
	if len(store.installed) != 0 {
		t.Fatalf("installed = %+v", store.installed)
	}
}

func TestClearInstallsAnEmptySet(t *testing.T) {
	store := &fakePublicationStore{}
	commands := OperatorCommands{Store: store, NewUUID: func() (ids.UUID, error) { return fixedUUID(t, "22222222-2222-2222-2222-222222222222"), nil }}
	payload := json.RawMessage(`{"family":"board"}`)
	command, err := operator.NewCommand("publication.clear", operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: "global", Reason: "test", SemanticKey: "k3"}, payload)
	if err != nil {
		t.Fatal(err)
	}
	result, err := commands.clearHandler(context.Background(), tx.Scope{Tx: publicationTx{}}, command)
	if err != nil {
		t.Fatal(err)
	}
	if len(store.installed) != 1 || len(store.installed[0].Items) != 0 {
		t.Fatalf("installed = %+v", store.installed)
	}
	view, ok := result.(FamilyView)
	if !ok || view.Visible {
		t.Fatalf("result = %+v", result)
	}
}

func TestShowReportsTheSelectedSetPerFamily(t *testing.T) {
	store := &fakePublicationStore{visible: true, selects: map[string]pub.Set{
		pub.Announcement: {ID: fixedUUID(t, "33333333-3333-3333-3333-333333333333"), Family: pub.Announcement, StartsAt: time.Now(), Items: []pub.Item{{Announcement: &pub.Section{Title: "t"}}}},
		pub.Picture:      {ID: fixedUUID(t, "44444444-4444-4444-4444-444444444444"), Family: pub.Picture, StartsAt: time.Now(), Items: []pub.Item{{Picture: &pub.PictureItem{Pic: "http://example/p.png"}}}},
	}}
	read := OperatorRead{Runner: tx.Runner{DB: publicationRunner{}}, Operations: operation.Factory{Clock: clock.System{}}, Store: store}
	reply, err := read.Show(context.Background(), "", 0)
	if err != nil {
		t.Fatal(err)
	}
	if len(reply.Families) != 2 {
		t.Fatalf("families = %+v", reply.Families)
	}
	if reply.Families[0].Family != pub.Announcement || !reply.Families[0].Visible || reply.Families[0].SetID != "33333333-3333-3333-3333-333333333333" {
		t.Fatalf("announcement = %+v", reply.Families[0])
	}
	if reply.Families[1].Family != pub.Picture {
		t.Fatalf("picture = %+v", reply.Families[1])
	}
}

func TestShowRefusesAnUnknownFamily(t *testing.T) {
	read := OperatorRead{Runner: tx.Runner{DB: publicationRunner{}}, Operations: operation.Factory{Clock: clock.System{}}, Store: &fakePublicationStore{}}
	if _, err := read.Show(context.Background(), "ghost", 0); err == nil {
		t.Fatal("an unknown family was accepted")
	}
}
