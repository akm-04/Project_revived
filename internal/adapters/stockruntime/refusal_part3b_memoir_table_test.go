package stockruntime

import (
	"errors"
	"net/http"
	"testing"

	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	memoirdomain "gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

func TestPart3BMemoirFailureRows(t *testing.T) {
	assertPart2FailureCases(t, []part2FailureCase{
		{"invalid", memoirFailure(memoirdomain.ErrInvalid), http.StatusBadRequest, 0, "memoir_invalid_parameter"},
		{"conflict", memoirFailure(&receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"report expired", memoirFailure(memoirdomain.ErrReportExpired), http.StatusConflict, memoirdomain.ReportExpiredCode, ""},
		{"fight unavailable", memoirFailure(memoirdomain.ErrFightUnavailable), http.StatusConflict, memoirdomain.FightUnavailableCode, ""},
		{"refused", memoirFailure(memoirdomain.ErrRefused), http.StatusConflict, unprovenRefusalCode, ""},
		{"balance stamina", memoirFailure(economy.InsufficientBalance("energy")), http.StatusConflict, insufficientStaminaCode, ""},
		{"start conflict", memoirFailure(combat.ErrStartConflict), http.StatusConflict, unprovenRefusalCode, ""},
		{"unavailable", memoirFailure(memoirdomain.ErrUnavailable), http.StatusConflict, unprovenRefusalCode, ""},
		{"dependency", memoirFailure(errors.New("database unavailable")), http.StatusInternalServerError, unprovenRefusalCode, ""},
	})
}
