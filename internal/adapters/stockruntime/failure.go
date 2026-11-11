package stockruntime

import (
	"errors"
	"fmt"
	"net/http"

	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// D5 PRIVATE_POLICY tunables. The balance codes are selected from the typed
// economy balance error's resource key.
const (
	unprovenRefusalCode     int64 = 35028
	staleConflictCode       int64 = 40002
	serverBusyCode          int64 = 35033
	insufficientDiamondCode int64 = 20005
	insufficientCoinCode    int64 = 20006
	insufficientStaminaCode int64 = 20007
)

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

func unknownCommit(detail string, cause error) *classifiedFailure {
	return &classifiedFailure{class: failureUnknownCommit, detail: detail, cause: cause}
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

// failureFromRows maps a dispatcher's domain errors to the client reply. A
// receipt conflict is D5's stale-state refusal; the fallback is a server fault.
func failureFromRows(rows []failureRow, err error) httpedge.Response {
	var conflict *receipt.ConflictError
	if errors.As(err, &conflict) {
		return failureReply(&classifiedFailure{class: failureRefusal, code: staleConflictCode, cause: err})
	}
	if classified := classifyFailure(rows, err); classified != nil {
		return failureReply(classified)
	}
	return failureReply(unavailable(err))
}

func failureReply(failure *classifiedFailure) httpedge.Response {
	switch failure.class {
	case failureMalformed:
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Cause: failure.cause, Body: map[string]any{"error": failure.detail}}
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
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": failure.detail}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": "unclassified_failure"}}
}

// The three protocol-edge statuses below sit outside the mapper's refusal
// classes (auth, region and unsupported-MID); their bodies stay unchanged.
func unauthorizedFailure(detail string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusUnauthorized, Body: map[string]any{"error_code": int64(1), "error": detail}}
}

func forbiddenFailure(detail string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusForbidden, Body: map[string]any{"error_code": int64(1), "error": detail}}
}

func notImplementedFailure(detail string) httpedge.Response {
	return httpedge.Response{HTTPStatus: http.StatusNotImplemented, Body: map[string]any{"error_code": int64(1), "error": detail}}
}
