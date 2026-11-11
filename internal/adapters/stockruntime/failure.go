package stockruntime

import (
	"errors"
	"fmt"
	"net/http"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// D5 PRIVATE_POLICY tunables. The balance codes apply only where a typed
// resource key identifies the missing resource; the shared
// economy.ErrInsufficientBalance carries none, so those rows use the generic.
const (
	unprovenRefusalCode     int64 = 35028
	staleConflictCode       int64 = 40002
	serverBusyCode          int64 = 35033
	insufficientDiamondCode int64 = 20005
	insufficientCoinCode    int64 = 20006
	insufficientStaminaCode int64 = 20007
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
	match  error
	class  failureClass
	code   int64
	detail string
}

func classifyFailure(rows []failureRow, err error) *classifiedFailure {
	for _, row := range rows {
		if !errors.Is(err, row.match) {
			continue
		}
		return &classifiedFailure{class: row.class, code: row.code, detail: row.detail, cause: err}
	}
	return nil
}

func failureReply(failure *classifiedFailure) httpedge.Response {
	switch failure.class {
	case failureMalformed:
		return httpedge.Response{HTTPStatus: http.StatusBadRequest, Cause: failure.cause, Body: map[string]any{"error": failure.detail}}
	case failureRefusal:
		body := make(map[string]any, len(failure.extra)+1)
		for key, value := range failure.extra {
			body[key] = value
		}
		body["error_code"] = failure.code
		return httpedge.Response{HTTPStatus: http.StatusConflict, Cause: failure.cause, Body: body}
	case failureUnavailable:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error_code": serverBusyCode, "error_msg": ""}}
	case failureDefect:
		return httpedge.Response{HTTPStatus: http.StatusInternalServerError, Cause: failure.cause, Body: map[string]any{"error_code": unprovenRefusalCode}}
	case failureUnknownCommit:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": failure.detail}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": "unclassified_failure"}}
}
