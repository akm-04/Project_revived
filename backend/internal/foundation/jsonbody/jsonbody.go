// Package jsonbody is the strict "one JSON value" check both HTTP edges share:
// the operator listener and the agent's local API. It lives in the foundation so
// neither adapter imports the other's application package.
package jsonbody

import (
	"encoding/json"
	"errors"
	"io"
)

// ErrTrailingData reports that a JSON document carried a second value. Callers
// that answer HTTP map it to their own status.
var ErrTrailingData = errors.New("trailing data after the JSON object")

// EnsureEndOfFile refuses a decoder that has another JSON value after the
// document.
func EnsureEndOfFile(decoder *json.Decoder) error {
	var extra any
	if err := decoder.Decode(&extra); errors.Is(err, io.EOF) {
		return nil
	} else if err != nil {
		return err
	}
	return ErrTrailingData
}
