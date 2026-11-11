package stockruntime

import (
	"errors"
	"net/http"
	"testing"

	app "gxb.local/backend/v2/internal/application/eventcentre"
	"gxb.local/backend/v2/internal/domain/bookskill"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestPart3BEventCentreFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"rejected", failEventCentre(app.ErrRejected), http.StatusConflict, unprovenRefusalCode, ""},
		{"invalid", failEventCentre(app.ErrInvalid), http.StatusConflict, unprovenRefusalCode, ""},
		{"unqualified", failEventCentre(app.ErrUnqualified), http.StatusConflict, unprovenRefusalCode, ""},
		{"stale", failEventCentre(app.ErrStale), http.StatusConflict, staleConflictCode, ""},
		{"stale time", failEventCentre(app.ErrStaleTime), http.StatusConflict, staleConflictCode, ""},
		{"book invalid", failEventCentre(bookskill.ErrInvalid), http.StatusConflict, unprovenRefusalCode, ""},
		{"conflict", failEventCentre(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"balance diamonds", failEventCentre(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance coins", failEventCentre(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"balance stamina", failEventCentre(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"unavailable", failEventCentre(app.ErrUnavailable), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"dependency", failEventCentre(errors.New("database unavailable")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"malformed params", eventCentreRefusal(), http.StatusConflict, unprovenRefusalCode, ""},
	})
	assertPart2FailureCases(t, []part2FailureCase{
		{"exchange diamonds", failEventCentreCommand(economy.InsufficientBalance("crystal"), app.Command{Family: app.AdminExchange, FromType: 2}), http.StatusConflict, insufficientDiamondCode, ""},
		{"exchange coins", failEventCentreCommand(economy.InsufficientBalance("mana"), app.Command{Family: app.AdminExchange, FromType: 1}), http.StatusConflict, insufficientCoinCode, ""},
		{"exchange other", failEventCentreCommand(economy.InsufficientBalance("guild_coin"), app.Command{Family: app.AdminExchange, FromType: 3}), http.StatusConflict, unprovenRefusalCode, ""},
	})
}
