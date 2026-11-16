package i4store

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type supersededRow struct {
	scan func(dest ...any) error
}

func (r supersededRow) Scan(dest ...any) error { return r.scan(dest...) }

type recordedQuery struct {
	query string
	args  []any
}

type supersededQueryer struct {
	rows    []tx.Row
	queries []recordedQuery
}

func (q *supersededQueryer) QueryRow(_ context.Context, query string, args ...any) tx.Row {
	q.queries = append(q.queries, recordedQuery{query: query, args: args})
	if len(q.rows) == 0 {
		return supersededRow{scan: func(...any) error { return errors.New("unexpected query") }}
	}
	row := q.rows[0]
	q.rows = q.rows[1:]
	return row
}

func supersededAuthority(q tx.Queryer) RealtimeAuthority {
	return RealtimeAuthority{
		Queryer:         q,
		DigestSecret:    []byte("superseded-unit-digest-secret"),
		BearerSecret:    []byte("superseded-unit-bearer-secret"),
		DerivationKeyID: "superseded-unit",
	}
}

func supersededBoolRow(value bool) tx.Row {
	return supersededRow{scan: func(dest ...any) error {
		*(dest[0].(*bool)) = value
		return nil
	}}
}

func TestResolveGameplayBearerClassifiesSupersededContext(t *testing.T) {
	q := &supersededQueryer{rows: []tx.Row{
		supersededRow{scan: func(...any) error { return kernelstore.ErrNoRows }},
		supersededBoolRow(true),
	}}
	_, err := supersededAuthority(q).ResolveGameplayBearer(context.Background(), "old-bearer", time.Unix(100, 0))
	if !errors.Is(err, ErrContextSuperseded) {
		t.Fatalf("err = %v, want ErrContextSuperseded", err)
	}
	if len(q.queries) != 2 {
		t.Fatalf("queries = %d, want the live lookup and one classification read", len(q.queries))
	}
	classify := q.queries[1].query
	for _, needle := range []string{"gameplay_context_credentials", "JOIN gameplay_contexts", "JOIN account_sessions", "end_reason='superseded'", "s.revoked_at IS NULL"} {
		if !strings.Contains(classify, needle) {
			t.Fatalf("classification query missing %q:\n%s", needle, classify)
		}
	}
	if strings.Contains(classify, "c.ended_at IS NULL") {
		t.Fatalf("classification query kept the liveness filter:\n%s", classify)
	}
}

func TestResolveGameplayBearerKeepsNotLiveWhenContextIsNotSuperseded(t *testing.T) {
	q := &supersededQueryer{rows: []tx.Row{
		supersededRow{scan: func(...any) error { return kernelstore.ErrNoRows }},
		supersededBoolRow(false),
	}}
	_, err := supersededAuthority(q).ResolveGameplayBearer(context.Background(), "revoked-bearer", time.Unix(100, 0))
	if !errors.Is(err, ErrGameplayBearerNotLive) {
		t.Fatalf("err = %v, want ErrGameplayBearerNotLive", err)
	}
}

func TestResolveGameplayBearerClassificationReadFailureSurfaces(t *testing.T) {
	fault := errors.New("classification read failed")
	q := &supersededQueryer{rows: []tx.Row{
		supersededRow{scan: func(...any) error { return kernelstore.ErrNoRows }},
		supersededRow{scan: func(...any) error { return fault }},
	}}
	_, err := supersededAuthority(q).ResolveGameplayBearer(context.Background(), "old-bearer", time.Unix(100, 0))
	if !errors.Is(err, fault) {
		t.Fatalf("err = %v, want the classification failure", err)
	}
}
