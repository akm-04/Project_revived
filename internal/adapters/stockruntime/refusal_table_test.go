package stockruntime

import (
	"net/http"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
)

func TestHeroFailureRowTable(t *testing.T) {
	cases := []struct {
		name       string
		err        error
		wantStatus int
		wantCode   int64
		wantError  string
	}{
		{"appearance unavailable", apphero.ErrHeroAppearanceUnavailable, http.StatusConflict, unprovenRefusalCode, ""},
		{"exp max", apphero.ErrHeroExpMax, http.StatusConflict, unprovenRefusalCode, ""},
		{"evolution unavailable", apphero.ErrHeroEvolutionUnavailable, http.StatusConflict, unprovenRefusalCode, ""},
		{"prerequisites", apphero.ErrHeroPrerequisites, http.StatusConflict, unprovenRefusalCode, ""},
		{"hero not found", apphero.ErrHeroNotFound, http.StatusConflict, unprovenRefusalCode, ""},
		{"capacity exceeded", apphero.ErrHeroCapacityExceeded, http.StatusConflict, unprovenRefusalCode, ""},
		{"duplicate origin", apphero.ErrHeroDuplicateOrigin, http.StatusConflict, unprovenRefusalCode, ""},
		{"acquisition invalid", apphero.ErrHeroAcquisitionInvalid, http.StatusBadRequest, 0, "hero_operation_rejected"},
		{"vows level", apphero.ErrHeroVowsLevel, http.StatusConflict, unprovenRefusalCode, ""},
		{"equipment unavailable", apphero.ErrHeroEquipmentUnavailable, http.StatusConflict, unprovenRefusalCode, ""},
		{"fumo unavailable", apphero.ErrHeroFumoUnavailable, http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion unavailable", apphero.ErrHeroPromotionUnavailable, http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion prerequisites", apphero.ErrHeroPromotionPrerequisites, http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion corrupt state", apphero.ErrHeroPromotionCorruptState, http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"hero content inactive", apphero.ErrHeroContentInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"appearance content inactive", apphero.ErrAppearanceContentInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"progression content inactive", apphero.ErrHeroProgressionContentInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"equipment content inactive", apphero.ErrHeroEquipmentContentInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"fumo content inactive", apphero.ErrHeroFumoContentInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"promotion content inactive", apphero.ErrHeroPromotionContentInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"capacity unavailable", apphero.ErrHeroCapacityUnavailable, http.StatusInternalServerError, unprovenRefusalCode, ""},
	}
	for _, row := range cases {
		t.Run(row.name, func(t *testing.T) {
			got := failHero(row.err)
			if got.HTTPStatus != row.wantStatus {
				t.Fatalf("status=%d want=%d body=%#v", got.HTTPStatus, row.wantStatus, got.Body)
			}
			if row.wantCode != 0 {
				if got.Body["error_code"] != row.wantCode {
					t.Fatalf("error_code=%#v want=%d", got.Body["error_code"], row.wantCode)
				}
				return
			}
			if got.Body["error"] != row.wantError {
				t.Fatalf("error=%#v want=%q", got.Body["error"], row.wantError)
			}
		})
	}
	fallback := failHero(anonymousFailure{})
	if fallback.HTTPStatus != http.StatusInternalServerError || fallback.Body["error_code"] != unprovenRefusalCode || fallback.Body["error_msg"] != "" {
		t.Fatalf("fallback=%+v", fallback)
	}
}

func TestHeroSkillLevelFailureRowTable(t *testing.T) {
	cases := []struct {
		name       string
		err        error
		wantStatus int
		wantCode   int64
		wantError  string
	}{
		{"invalid request", apphero.ErrHeroSkillLevelRequest, http.StatusBadRequest, 0, "invalid_hero_skill_level"},
		{"content inactive", apphero.ErrHeroSkillLevelInactive, http.StatusConflict, unprovenRefusalCode, ""},
		{"stale time", apphero.ErrHeroSkillLevelStaleTime, http.StatusConflict, staleConflictCode, ""},
	}
	for _, row := range cases {
		t.Run(row.name, func(t *testing.T) {
			got := failHeroSkillLevel(row.err)
			if got.HTTPStatus != row.wantStatus {
				t.Fatalf("status=%d want=%d body=%#v", got.HTTPStatus, row.wantStatus, got.Body)
			}
			if row.wantCode != 0 {
				if got.Body["error_code"] != row.wantCode {
					t.Fatalf("error_code=%#v want=%d", got.Body["error_code"], row.wantCode)
				}
				return
			}
			if got.Body["error"] != row.wantError {
				t.Fatalf("error=%#v want=%q", got.Body["error"], row.wantError)
			}
		})
	}
}

// clientMessageIDs embeds the 117 ids in the stock
// tmp/virtualclient/src_64/data/tables/message.lua rows table.
var clientMessageIDs = map[int64]bool{
	10001: true, 10002: true, 10003: true, 10004: true,
	20001: true, 20002: true, 20003: true, 20004: true, 20005: true, 20006: true, 20007: true,
	20008: true, 20009: true, 20010: true, 20011: true, 20012: true, 20013: true, 20014: true,
	20015: true, 20016: true, 20017: true, 20018: true, 20028: true, 20029: true, 20030: true,
	20031: true, 20032: true, 20033: true,
	30001: true, 30002: true, 30003: true, 30004: true,
	30010: true, 30011: true, 30012: true, 30013: true, 30014: true, 30015: true, 30016: true,
	30017: true, 30018: true, 30019: true, 30020: true, 30021: true, 30022: true, 30023: true,
	31001: true, 31002: true, 31003: true, 31004: true, 31006: true, 33001: true, 33002: true,
	34001: true, 34002: true, 34003: true, 34004: true, 34005: true, 34006: true, 34007: true,
	34008: true, 34009: true, 34010: true, 34011: true, 34012: true, 34013: true, 34014: true,
	34015: true, 34016: true, 34017: true, 34018: true, 34019: true, 34020: true, 34021: true,
	34022: true,
	35001: true, 35002: true, 35003: true, 35004: true, 35005: true, 35006: true, 35007: true,
	35008: true, 35009: true, 35010: true, 35011: true, 35012: true, 35013: true, 35014: true,
	35015: true, 35016: true, 35017: true, 35018: true, 35019: true, 35020: true, 35021: true,
	35022: true, 35023: true, 35024: true, 35025: true, 35026: true, 35027: true, 35028: true,
	35029: true, 35030: true, 35031: true, 35032: true, 35033: true, 35034: true, 35035: true,
	35036: true,
	40001: true, 40002: true, 40003: true, 40004: true, 40005: true, 50000: true,
}

func TestRefusalCodesHaveClientMessageRows(t *testing.T) {
	if len(clientMessageIDs) != 117 {
		t.Fatalf("client message fixture holds %d ids, want 117", len(clientMessageIDs))
	}
	rows := append([]failureRow{}, bookFailureRows...)
	rows = append(rows, heroFailureRows...)
	rows = append(rows, heroSkillLevelFailureRows...)
	for _, row := range rows {
		if row.class != failureRefusal || row.code == unprovenRefusalCode || row.balance {
			continue
		}
		if !clientMessageIDs[row.code] {
			t.Errorf("refusal code %d has no client message row", row.code)
		}
	}
	for _, code := range []int64{20018, 35035, serverBusyCode, staleConflictCode} {
		if !clientMessageIDs[code] {
			t.Errorf("refusal code %d has no client message row", code)
		}
	}
}
