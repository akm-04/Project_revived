package stockruntime

import (
	"net/http"
	"testing"

	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/economy"
	room "gxb.local/backend/v2/internal/domain/sharedroom"
)

func TestPart3CAdventureFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failAdventure(d.ErrInvalid), http.StatusBadRequest, 0, "adventure_invalid_parameter"},
		{"expired", failAdventure(d.ErrExpired), http.StatusConflict, adventureExpired, ""},
		{"refused", failAdventure(d.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"not in room", failAdventure(sr.ErrNotInRoom), http.StatusConflict, unprovenRefusalCode, ""},
		{"room full", failAdventure(room.ErrFull), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance diamonds", failAdventure(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance coins", failAdventure(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"balance stamina", failAdventure(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"balance other", failAdventure(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"unknown resource", failAdventure(economy.ErrUnknownResource), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"unavailable", failAdventure(d.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}
