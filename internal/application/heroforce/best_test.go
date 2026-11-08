package heroforce

import (
	"context"
	"strings"
	"testing"
	"time"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/statrules"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type bestTx struct{}

func (bestTx) QueryRow(context.Context, string, ...any) tx.Row             { return nil }
func (bestTx) Exec(context.Context, string, ...any) (tx.CommandTag, error) { return nil, nil }
func (bestTx) Commit(context.Context) error                                { return nil }
func (bestTx) Rollback(context.Context) error                              { return nil }

type bestStats map[int64]float64

func (s bestStats) HeroTx(_ context.Context, _ ca.CoherentReadScope, ref character.HeroRef, _ publicstats.View) (publicstats.Result, error) {
	return publicstats.Result{Stats: statrules.Result{Force: s[ref.PartnerID]}}, nil
}

func TestBestSumsStrongestCount(t *testing.T) {
	at := time.Unix(100, 0).UTC()
	timed, e := gen.NewTimedOperation(operation.Context{ID: ids.UUID{1}, StartedAt: at}, at)
	if e != nil {
		t.Fatal(e)
	}
	sc := gen.TimedScope{Tx: bestTx{}, Operation: timed, Attempt: 1, Options: tx.Options{Isolation: tx.RepeatableRead}}
	stats := bestStats{1: 10, 2: 20, 3: 30, 4: 40, 5: 50, 6: 60}
	revision := strings.Repeat("a", 64)
	got, e := Best(context.Background(), 5, sc, stats, 1, revision, at, []int64{1, 2, 3, 4, 5, 6})
	if e != nil || got != 200 {
		t.Fatal(got, e)
	}
	got, e = Best(context.Background(), 15, sc, stats, 1, revision, at, []int64{1, 2, 3})
	if e != nil || got != 60 {
		t.Fatal(got, e)
	}
}
