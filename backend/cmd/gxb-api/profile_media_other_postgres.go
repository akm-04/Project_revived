//go:build postgres && !linux

package main

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"net/http"
)

func registerProfileMedia(context.Context, *pg.Pool, tx.Runner, realtimeauth.GameplayAuthorityPort, receipt.Store, contentstore.Store, *httpedge.Router, string, string) (http.Handler, error) {
	return nil, errors.New("qualified profile media local adapter requires Linux")
}
