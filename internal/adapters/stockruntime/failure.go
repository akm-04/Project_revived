package stockruntime

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"strings"

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

// D5 PRIVATE_POLICY tunables. The balance codes are selected from the typed
// economy balance error's resource key.
const (
	unprovenRefusalCode     int64 = 35028
	staleConflictCode       int64 = 40002
	serverBusyCode          int64 = 35033
	sessionFailureCode      int64 = 20003
	insufficientDiamondCode int64 = 20005
	insufficientCoinCode    int64 = 20006
	insufficientStaminaCode int64 = 20007
)

// sessionFailureMessage is message.lua row 20003
// (tmp/virtualclient/src_64/data/tables/message.lua:44-48, "登錄失敗"/"Login
// failed"). Backend.lua:428-447 opens the one-button alert that restarts the
// game only for a non-empty error_msg; an empty one only toasts and leaves the
// player stuck on the dead session. PRIVATE_POLICY tunable: the stock row text
// is the default, an operator may change it.
const sessionFailureMessage = "Unstable network,try to relog in!"

// Stock resource keys: crystal is the diamond wallet (eventcentre admin
// exchange from_type 2 -> 20005), mana is the coin wallet (from_type 1 ->
// 20006, message.lua 20005/20006), and energy is stamina (client enums.lua
// ENERGY = "energy", utils.lua asset "energy"; message.lua 20007).
const (
	diamondResourceKey = "crystal"
	coinResourceKey    = "mana"
	staminaResourceKey = "energy"
)

type failureClass uint8

const (
	failureMalformed failureClass = iota + 1
	failureRefusal
	failureUnavailable
	failureDefect
	failureUnknownCommit
	failureSession
)

type classifiedFailure struct {
	class  failureClass
	code   int64
	detail string
	extra  map[string]any
	cause  error
}

func (f *classifiedFailure) Error() string {
	if f.detail != "" {
		return f.detail
	}
	if f.code != 0 {
		return fmt.Sprintf("refusal %d", f.code)
	}
	return "classified failure"
}

func (f *classifiedFailure) Unwrap() error { return f.cause }

func malformed(detail string) *classifiedFailure {
	return &classifiedFailure{class: failureMalformed, detail: detail}
}

func refusal(code int64) *classifiedFailure {
	return &classifiedFailure{class: failureRefusal, code: code}
}

func refusalWithBody(code int64, body map[string]any) *classifiedFailure {
	return &classifiedFailure{class: failureRefusal, code: code, extra: body}
}

func unavailable(cause error) *classifiedFailure {
	return &classifiedFailure{class: failureUnavailable, cause: cause}
}

func defect(cause error) *classifiedFailure {
	return &classifiedFailure{class: failureDefect, cause: cause}
}

// refusalOrTransient keeps a bounded private refusal for any permanent fault,
// because those endpoints must never answer 200 or a generic defect body, while
// a retryable fault still gets the transient 503.
func refusalOrTransient(err error) httpedge.Response {
	if isTransient(err) {
		return failureReply(unavailable(err))
	}
	return failureReply(refusal(unprovenRefusalCode))
}

func unknownCommit(detail string, cause error) *classifiedFailure {
	return &classifiedFailure{class: failureUnknownCommit, detail: detail, cause: cause}
}

// sessionFailure marks an expired, replaced or invalid session/token (U6). Its
// non-empty error_msg is the message.lua 20003 text, so the client alerts and
// restarts into login instead of leaving the player on a dead session.
func sessionFailure() *classifiedFailure {
	return &classifiedFailure{class: failureSession}
}

// UnprovenRefusal is the named mapper entry for rows whose stock code has no
// client evidence (r4-mapper-table rows with code UNKNOWN or today's code 1).
func UnprovenRefusal() *classifiedFailure {
	return refusal(unprovenRefusalCode)
}

type failureRow struct {
	match   error
	class   failureClass
	code    int64
	detail  string
	balance bool
}

func classifyFailure(rows []failureRow, err error) *classifiedFailure {
	for _, row := range rows {
		if !errors.Is(err, row.match) {
			continue
		}
		code := row.code
		if row.balance {
			code = insufficientBalanceCode(err)
		}
		return &classifiedFailure{class: row.class, code: code, detail: row.detail, cause: err}
	}
	return nil
}

func insufficientBalanceCode(err error) int64 {
	var balance *economy.InsufficientBalanceError
	if !errors.As(err, &balance) {
		return unprovenRefusalCode
	}
	switch balance.ResourceKey {
	case diamondResourceKey:
		return insufficientDiamondCode
	case coinResourceKey:
		return insufficientCoinCode
	case staminaResourceKey:
		return insufficientStaminaCode
	}
	return unprovenRefusalCode
}

// sharedFailureRows apply to every failureFromRows call after the dispatcher's
// own rows. Content inactive is a permanent refusal (the content revision does
// not grant the capability); an unknown resource is a server defect because the
// caller named a resource the content compiler never defined.
var sharedFailureRows = []failureRow{
	{match: economy.ErrUnknownResource, class: failureDefect},
	{match: apphero.ErrHeroContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrAppearanceContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroProgressionContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroEquipmentContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrSuperEquipmentContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroFumoContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apphero.ErrHeroPromotionContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apppet.ErrPetAcquisitionContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apppet.ErrPetProgressionContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apppet.ErrPetEquipmentContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apppet.ErrPetPromotionContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apppet.ErrPetAppearanceContentInactive, class: failureRefusal, code: unprovenRefusalCode},
	{match: apppractice.ErrContentInactive, class: failureRefusal, code: unprovenRefusalCode},
}

// isTransient lists the faults where the same request may succeed later. A
// permanent refusal never answers 503 (D5 amendment).
func isTransient(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, context.DeadlineExceeded) || errors.Is(err, context.Canceled) {
		return true
	}
	if errors.Is(err, tx.ErrAdmissionClosed) {
		return true
	}
	if errors.Is(err, combat.ErrResolverRetryable) || errors.Is(err, appcombat.ErrWorkerSaturated) {
		return true
	}
	if errors.Is(err, httpedge.ErrSaturated) {
		return true
	}
	if tx.IsDefiniteAbortError(err) {
		return true
	}
	state := tx.SQLState(err)
	if strings.HasPrefix(state, "40") || strings.HasPrefix(state, "53") || strings.HasPrefix(state, "08") {
		return true
	}
	switch state {
	case "57P01", "55P03", "57014", "25P03":
		return true
	}
	// pgx v5 pgxpool returns the acquire context's deadline while waiting for a
	// connection, so the context checks above cover the pool acquire timeout.
	return false
}

// failureFromRows maps a dispatcher's domain errors to the client reply. A
// receipt conflict is D5's stale-state refusal; the shared rows cover inactivity
// and content defects; the fallback is transient only for a retryable fault.
func failureFromRows(rows []failureRow, err error) httpedge.Response {
	if classified := classifyFailure(rows, err); classified != nil {
		return failureReply(classified)
	}
	var conflict *receipt.ConflictError
	if errors.As(err, &conflict) {
		return failureReply(&classifiedFailure{class: failureRefusal, code: staleConflictCode, cause: err})
	}
	if classified := classifyFailure(sharedFailureRows, err); classified != nil {
		return failureReply(classified)
	}
	if isTransient(err) {
		return failureReply(unavailable(err))
	}
	return failureReply(defect(err))
}

func failureReply(failure *classifiedFailure) httpedge.Response {
	switch failure.class {
	case failureMalformed:
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Cause: failure.cause, Body: map[string]any{"error_code": unprovenRefusalCode, "error_msg": "", "error": failure.detail}}
	case failureRefusal:
		body := make(map[string]any, len(failure.extra)+2)
		for key, value := range failure.extra {
			body[key] = value
		}
		body["error_code"] = failure.code
		body["error_msg"] = ""
		return httpedge.Response{HTTPStatus: http.StatusConflict, Cause: failure.cause, Body: body}
	case failureUnavailable:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error_code": serverBusyCode, "error_msg": ""}}
	case failureDefect:
		return httpedge.Response{HTTPStatus: http.StatusInternalServerError, Cause: failure.cause, Body: map[string]any{"error_code": unprovenRefusalCode, "error_msg": ""}}
	case failureUnknownCommit:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error_code": serverBusyCode, "error_msg": "", "error": failure.detail}}
	case failureSession:
		return httpedge.Response{HTTPStatus: http.StatusUnauthorized, Cause: failure.cause, Body: map[string]any{"error_code": sessionFailureCode, "error_msg": sessionFailureMessage}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error_code": serverBusyCode, "error_msg": ""}}
}

// Unsupported and region-mismatch replies are permanent refusals through
// refusal(unprovenRefusalCode); authentication failures are sessionFailure.
