package playerdisplay

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type fixedCatalogOwner struct{ err error }

func (o fixedCatalogOwner) ReadCatalogDisplayOriginsTx(_ context.Context, _ tx.Queryer, r CatalogOriginRequest) (CatalogOriginObservation, error) {
	if o.err != nil {
		return CatalogOriginObservation{}, o.err
	}
	origin := Origin{PlayerID: r.PlayerID, Key: "k", Owner: "fixture", Family: r.Family, CatalogID: r.CatalogID, Revision: r.Revision, StateVersion: 1}
	return CatalogOriginObservation{Request: r, Qualified: true, CompleteHistory: true, Origins: []Origin{origin}}, nil
}

func TestFamilyOriginsUnionOfCoveredOwnersOnly(t *testing.T) {
	rev := strings.Repeat("a", 64)
	at := time.Unix(100, 0).UTC()
	catalog := player.DisplayCatalog{Cosmetics: []player.Cosmetic{{Family: "title", ID: 5}, {Family: "title", ID: 6}, {Family: "bubble", ID: 5}}}
	s := Service{CatalogExternal: CatalogOriginRoutes{{Family: "title", First: 5, Last: 5, Owner: fixedCatalogOwner{}}}}
	origins, e := s.familyOrigins(context.Background(), nil, 7, "title", catalog, rev, at)
	if e != nil || len(origins) != 1 || origins[0].CatalogID != 5 {
		t.Fatalf("uncovered id must be absent: %+v %v", origins, e)
	}
	s.CatalogExternal = CatalogOriginRoutes{{Family: "title", First: 5, Last: 5, Owner: fixedCatalogOwner{err: ErrUnavailable}}}
	if _, e = s.familyOrigins(context.Background(), nil, 7, "title", catalog, rev, at); !errors.Is(e, ErrUnavailable) || errors.Is(e, ErrUncovered) {
		t.Fatalf("a covering owner's unavailability must fail the list: %v", e)
	}
}
