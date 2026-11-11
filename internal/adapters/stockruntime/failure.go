package stockruntime

import (
	"errors"
	"fmt"
	"net/http"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// unprovenRefusalCode is the single PRIVATE_POLICY tunable for refusals whose
// stock code has no client evidence yet. 1 reproduces today's silent reply.
const unprovenRefusalCode int64 = 1

type failureClass uint8

const (
	failureMalformed failureClass = iota + 1
	failureRefusal
	failureUnavailable
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

func unavailable(detail string, cause error) *classifiedFailure {
	return &classifiedFailure{class: failureUnavailable, detail: detail, cause: cause}
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
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": failure.detail}}
	case failureUnknownCommit:
		return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": failure.detail}}
	}
	return httpedge.Response{HTTPStatus: http.StatusServiceUnavailable, Cause: failure.cause, Body: map[string]any{"error": "unclassified_failure"}}
}
