package stockruntime

import (
	"errors"
	"net/http"
	"testing"

	domain "gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestPart3BDodgeballFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", dodgeballFailure(domain.ErrInvalid), http.StatusBadRequest, 0, "dodgeball_invalid_parameter"},
		{"conflict", dodgeballFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"refused", dodgeballFailure(domain.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance diamonds", dodgeballFailure(economy.InsufficientBalance("crystal")), http.StatusConflict, insufficientDiamondCode, ""},
		{"balance coins", dodgeballFailure(economy.InsufficientBalance("mana")), http.StatusConflict, insufficientCoinCode, ""},
		{"balance stamina", dodgeballFailure(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"balance other", dodgeballFailure(economy.InsufficientBalance("guild_coin")), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", dodgeballFailure(domain.ErrUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"dependency", dodgeballFailure(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
}
