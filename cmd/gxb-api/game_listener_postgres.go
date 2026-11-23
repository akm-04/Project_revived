//go:build postgres

package main

import (
	"fmt"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
)

// parseGameListener reads GXB_GAME_LISTENER: unset or "open" keeps the stock
// game listener, "closed" leaves it unbound for a rebuild or restore, and any
// other value is fatal (I11A_1_PLAN "Agent decisions").
func parseGameListener(value string) (bool, error) {
	switch value {
	case "", "open":
		return true, nil
	case "closed":
		return false, nil
	default:
		return false, fmt.Errorf("GXB_GAME_LISTENER must be open or closed, got %q", value)
	}
}

// refuseOpenWithoutAssets reports whether an open start must be refused because
// no ACTIVE assets release is published. An unreadable release record refuses
// too: an open backend that cannot prove the assets are published must not
// serve the client.
func refuseOpenWithoutAssets(open bool, state *appotarelease.StateFile) bool {
	if !open || state == nil {
		return false
	}
	active, err := state.HasActiveAssets()
	return err != nil || !active
}
