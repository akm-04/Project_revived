package stockruntime

import (
	"net/http"
	"testing"

	sr "gxb.local/backend/v2/internal/application/sharedroom"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	privilege "gxb.local/backend/v2/internal/domain/privilege"
	room "gxb.local/backend/v2/internal/domain/sharedroom"
	"gxb.local/backend/v2/internal/foundation/receipt"
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

func TestPart3CCampaignFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", failCampaign(campaign.ErrInvalid), http.StatusBadRequest, 0, "campaign_invalid_parameter"},
		{"conflict", failCampaign(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"loan refused", failCampaign(combat.ErrLoanRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"refused", failCampaign(campaign.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", failCampaign(campaign.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}

func TestPart3CChargeFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"charge refused", failCharge(privilege.ErrChargeRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failCharge(privilege.ErrConflict), http.StatusConflict, staleConflictCode, ""},
		{"receipt conflict", failCharge(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"unavailable", failCharge(privilege.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
	})
}
