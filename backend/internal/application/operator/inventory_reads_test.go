package operator

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type inventoryRunner struct{}

func (inventoryRunner) Begin(context.Context, tx.Options) (tx.Tx, error) { return inventoryTx{}, nil }

type inventoryTx struct{}

func (inventoryTx) QueryRow(context.Context, string, ...any) tx.Row {
	return inventoryRow{err: errors.New("unexpected query")}
}
func (inventoryTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) {
	return inventoryTag(1), nil
}
func (inventoryTx) Commit(context.Context) error   { return nil }
func (inventoryTx) Rollback(context.Context) error { return nil }

type inventoryRow struct{ err error }

func (row inventoryRow) Scan(...any) error { return row.err }

type inventoryTag int64

func (tag inventoryTag) RowsAffected() int64 { return int64(tag) }

type fakeServerDirectory struct {
	servers []OperatorServer
}

func (fake fakeServerDirectory) OperatorServersTx(context.Context, tx.Queryer) ([]OperatorServer, error) {
	return fake.servers, nil
}

type fakeOnlineCounter struct {
	counts map[int64]int64
}

func (fake fakeOnlineCounter) OnlineCountsByServerTx(context.Context, tx.Queryer) (map[int64]int64, error) {
	return fake.counts, nil
}

func TestServerListJoinsTheLiveCountPerServer(t *testing.T) {
	service := ServerReadService{
		Runner:     tx.Runner{DB: inventoryRunner{}},
		Operations: operationForInventoryTest(),
		Servers:    fakeServerDirectory{servers: []OperatorServer{{ServerID: 1, Name: "One", Open: true}, {ServerID: 2, Name: "Two"}}},
		Online:     fakeOnlineCounter{counts: map[int64]int64{1: 7}},
	}
	page, err := service.List(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Servers) != 2 {
		t.Fatalf("servers = %+v", page.Servers)
	}
	if page.Servers[0].ServerID != 1 || page.Servers[0].OnlineCount != 7 || !page.Servers[0].Open {
		t.Fatalf("server 1 = %+v", page.Servers[0])
	}
	if page.Servers[1].ServerID != 2 || page.Servers[1].OnlineCount != 0 || page.Servers[1].Open {
		t.Fatalf("server 2 = %+v", page.Servers[1])
	}
}

type fakeOnlineSessions struct {
	rows  []OnlineSession
	seen  OnlineSessionFilter
	calls int
}

func (fake *fakeOnlineSessions) ListOnlineSessionsTx(_ context.Context, _ tx.Queryer, filter OnlineSessionFilter) ([]OnlineSession, error) {
	fake.seen = filter
	fake.calls++
	if len(fake.rows) > filter.Limit {
		return fake.rows[:filter.Limit], nil
	}
	return fake.rows, nil
}

type fakePlayerNames struct {
	names map[int64]string
	asked []int64
}

func (fake *fakePlayerNames) PlayerNamesTx(_ context.Context, _ tx.Queryer, ids []int64) (map[int64]string, error) {
	fake.asked = append([]int64(nil), ids...)
	out := make(map[int64]string, len(ids))
	for _, id := range ids {
		out[id] = fake.names[id]
	}
	return out, nil
}

func TestOnlineSessionsPageByNameAndCursor(t *testing.T) {
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	sessions := &fakeOnlineSessions{rows: []OnlineSession{
		{SessionID: "00000000-0000-0000-0000-000000000001", PlayerID: 10, ServerID: 1, StartedAt: at, LastSeenAt: at.Add(time.Minute), Online: true},
		{SessionID: "00000000-0000-0000-0000-000000000002", PlayerID: 11, ServerID: 1, StartedAt: at, LastSeenAt: at},
		{SessionID: "00000000-0000-0000-0000-000000000003", PlayerID: 12, ServerID: 2, StartedAt: at, LastSeenAt: at},
	}}
	names := &fakePlayerNames{names: map[int64]string{10: "Ten", 11: "Eleven"}}
	service := SessionReadService{Runner: tx.Runner{DB: inventoryRunner{}}, Operations: operationForInventoryTest(), Sessions: sessions, Players: names}
	page, err := service.Online(context.Background(), OnlineSessionFilter{Limit: 2})
	if err != nil {
		t.Fatal(err)
	}
	if len(page.Sessions) != 2 || page.Sessions[0].Name != "Ten" || page.Sessions[1].Name != "Eleven" {
		t.Fatalf("page = %+v", page)
	}
	if page.NextAfter != "00000000-0000-0000-0000-000000000002" {
		t.Fatalf("next_after = %q", page.NextAfter)
	}
	if !page.Sessions[0].Online || page.Sessions[1].Online {
		t.Fatalf("online flags = %+v", page.Sessions)
	}
	if len(names.asked) != 3 {
		t.Fatalf("names asked for %v", names.asked)
	}
}

func TestOnlineSessionsRefuseBadInput(t *testing.T) {
	service := SessionReadService{Runner: tx.Runner{DB: inventoryRunner{}}, Operations: operationForInventoryTest(), Sessions: &fakeOnlineSessions{}, Players: &fakePlayerNames{}}
	cases := []OnlineSessionFilter{
		{Limit: 201},
		{ServerID: pointerToInt64(0)},
		{After: "not-a-uuid"},
	}
	for _, filter := range cases {
		if _, err := service.Online(context.Background(), filter); err == nil {
			t.Fatalf("filter %+v was accepted", filter)
		}
	}
}

func TestOnlineSessionsPassTheServerFilterToTheOwner(t *testing.T) {
	sessions := &fakeOnlineSessions{}
	service := SessionReadService{Runner: tx.Runner{DB: inventoryRunner{}}, Operations: operationForInventoryTest(), Sessions: sessions, Players: &fakePlayerNames{names: map[int64]string{}}}
	server := int64(2)
	if _, err := service.Online(context.Background(), OnlineSessionFilter{ServerID: &server, Limit: 5}); err != nil {
		t.Fatal(err)
	}
	if sessions.seen.ServerID == nil || *sessions.seen.ServerID != 2 {
		t.Fatalf("server filter = %+v", sessions.seen.ServerID)
	}
}

func pointerToInt64(value int64) *int64 { return &value }

func operationForInventoryTest() operation.Factory {
	return operation.Factory{Clock: clock.System{}}
}
