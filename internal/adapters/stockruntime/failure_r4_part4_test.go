package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	apppet "gxb.local/backend/v2/internal/application/characterpet"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	appcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type sqlStateString string

func (e sqlStateString) Error() string    { return string(e) }
func (e sqlStateString) SQLState() string { return string(e) }

var failureClassSentinel = errors.New("class sentinel")

type failureBodyCase struct {
	name       string
	got        httpedge.Response
	wantStatus int
	wantCode   int64
	wantError  string
}

func assertFailureBodyCases(t *testing.T, cases []failureBodyCase) {
	t.Helper()
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if tc.got.HTTPStatus != tc.wantStatus {
				t.Fatalf("status=%d want=%d body=%#v", tc.got.HTTPStatus, tc.wantStatus, tc.got.Body)
			}
			if tc.got.Body["error_code"] != tc.wantCode {
				t.Fatalf("error_code=%#v want=%d", tc.got.Body["error_code"], tc.wantCode)
			}
			if tc.got.Body["error_msg"] != "" {
				t.Fatalf("error_msg=%#v want empty", tc.got.Body["error_msg"])
			}
			if tc.wantError != "" && tc.got.Body["error"] != tc.wantError {
				t.Fatalf("error=%#v want=%q", tc.got.Body["error"], tc.wantError)
			}
		})
	}
}

func TestR4Part4FailureClassTable(t *testing.T) {
	malformedRows := []failureRow{{match: failureClassSentinel, class: failureMalformed, detail: "bad_shape"}}
	refusalRows := []failureRow{{match: failureClassSentinel, class: failureRefusal, code: 35002}}
	assertFailureBodyCases(t, []failureBodyCase{
		{"malformed", failureFromRows(malformedRows, failureClassSentinel), http.StatusBadRequest, unprovenRefusalCode, "bad_shape"},
		{"refusal", failureFromRows(refusalRows, failureClassSentinel), http.StatusConflict, 35002, ""},
		{"stale", failureFromRows(nil, &receipt.ConflictError{}), http.StatusConflict, staleConflictCode, ""},
		{"transient", failureFromRows(nil, sqlStateString("40001")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"lock timeout", failureFromRows(nil, sqlStateString("55P03")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"statement timeout", failureFromRows(nil, sqlStateString("57014")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"idle transaction timeout", failureFromRows(nil, sqlStateString("25P03")), http.StatusServiceUnavailable, serverBusyCode, ""},
		{"unique violation", failureFromRows(nil, sqlStateString("23505")), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"defect", failureFromRows(nil, errors.New("plain failure")), http.StatusInternalServerError, unprovenRefusalCode, ""},
		{"unknown commit", failureReply(unknownCommit("practice_commit_unknown", errors.New("commit unknown"))), http.StatusServiceUnavailable, serverBusyCode, "practice_commit_unknown"},
		{"session", failureReply(sessionFailure()), http.StatusUnauthorized, sessionFailureCode, ""},
	})
}

func TestR4Part4SharedFailureRows(t *testing.T) {
	cases := []struct {
		name       string
		err        error
		wantStatus int
		wantCode   int64
	}{
		{"receipt conflict", &receipt.ConflictError{}, http.StatusConflict, staleConflictCode},
		{"unknown resource", economy.ErrUnknownResource, http.StatusInternalServerError, unprovenRefusalCode},
		{"hero content inactive", apphero.ErrHeroContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"appearance content inactive", apphero.ErrAppearanceContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"hero progression content inactive", apphero.ErrHeroProgressionContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"hero equipment content inactive", apphero.ErrHeroEquipmentContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"super equipment content inactive", apphero.ErrSuperEquipmentContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"hero fumo content inactive", apphero.ErrHeroFumoContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"hero promotion content inactive", apphero.ErrHeroPromotionContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"pet acquisition content inactive", apppet.ErrPetAcquisitionContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"pet progression content inactive", apppet.ErrPetProgressionContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"pet equipment content inactive", apppet.ErrPetEquipmentContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"pet promotion content inactive", apppet.ErrPetPromotionContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"pet appearance content inactive", apppet.ErrPetAppearanceContentInactive, http.StatusConflict, unprovenRefusalCode},
		{"practice content inactive", apppractice.ErrContentInactive, http.StatusConflict, unprovenRefusalCode},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := failureFromRows(nil, tc.err)
			if got.HTTPStatus != tc.wantStatus || got.Body["error_code"] != tc.wantCode || got.Body["error_msg"] != "" {
				t.Fatalf("status=%d body=%#v want=%d/%d", got.HTTPStatus, got.Body, tc.wantStatus, tc.wantCode)
			}
		})
	}
}

func TestR4Part4IsTransient(t *testing.T) {
	cases := []struct {
		name string
		err  error
		want bool
	}{
		{"serialization failure", sqlStateString("40001"), true},
		{"deadlock", sqlStateString("40P01"), true},
		{"connection exception", sqlStateString("08006"), true},
		{"too many connections", sqlStateString("53300"), true},
		{"admin shutdown", sqlStateString("57P01"), true},
		{"lock timeout", sqlStateString("55P03"), true},
		{"statement timeout", sqlStateString("57014"), true},
		{"idle transaction timeout", sqlStateString("25P03"), true},
		{"unique violation", sqlStateString("23505"), false},
		{"deadline", context.DeadlineExceeded, true},
		{"canceled", context.Canceled, true},
		{"admission closed", tx.ErrAdmissionClosed, true},
		{"combat retryable", combat.ErrResolverRetryable, true},
		{"combat saturated", appcombat.ErrWorkerSaturated, true},
		{"edge saturated", httpedge.ErrSaturated, true},
		{"plain failure", errors.New("x"), false},
		{"unknown resource", economy.ErrUnknownResource, false},
		{"content inactive", apphero.ErrHeroContentInactive, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := isTransient(tc.err); got != tc.want {
				t.Fatalf("isTransient(%v)=%v want=%v", tc.err, got, tc.want)
			}
		})
	}
}
