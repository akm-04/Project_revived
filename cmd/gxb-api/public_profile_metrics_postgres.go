//go:build postgres

package main

import (
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	lib "gxb.local/backend/v2/internal/application/librarylocal"
	app "gxb.local/backend/v2/internal/application/publicprofile"
)

func canonicalProfileMetrics(content contentstore.Store) app.CanonicalMetricProvider {
	return app.CanonicalMetricProvider{Roster: characterstore.RosterMetricReader{Store: characterstore.Store{}, Content: content}, Creation: app.CanonicalCreationMetricProvider{Players: i5store.Store{}}, Library: lib.Service{Heroes: characterstore.LibraryHeroPort{Store: characterstore.Store{}}, Library: librarystore.Store{}, Content: content}}
}
