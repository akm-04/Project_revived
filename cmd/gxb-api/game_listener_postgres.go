//go:build postgres

package main

import "fmt"

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
