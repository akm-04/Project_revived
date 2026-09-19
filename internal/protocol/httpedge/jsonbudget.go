package httpedge

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
)

var errJSONBudget = errors.New("json budget exceeded")

func decodeJSONObject(data []byte, maxDepth, maxNodes int) (map[string]any, error) {
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.UseNumber()
	var v any
	if err := dec.Decode(&v); err != nil {
		return nil, err
	}
	var extra any
	if err := dec.Decode(&extra); err != io.EOF {
		return nil, errors.New("multiple JSON values")
	}
	nodes := 0
	var walk func(any, int) error
	walk = func(x any, d int) error {
		nodes++
		if d > maxDepth || nodes > maxNodes {
			return errJSONBudget
		}
		switch y := x.(type) {
		case map[string]any:
			for _, z := range y {
				if err := walk(z, d+1); err != nil {
					return err
				}
			}
		case []any:
			for _, z := range y {
				if err := walk(z, d+1); err != nil {
					return err
				}
			}
		}
		return nil
	}
	if err := walk(v, 1); err != nil {
		return nil, err
	}
	m, ok := v.(map[string]any)
	if !ok {
		return nil, errors.New("top-level JSON must be object")
	}
	return m, nil
}
func numericMID(v any) (uint16, bool) {
	n, ok := v.(json.Number)
	if !ok {
		return 0, false
	}
	i, e := n.Int64()
	if e != nil || i < 0 || i > 65535 {
		return 0, false
	}
	return uint16(i), true
}
func intClaim(v any) (int64, bool) {
	n, ok := v.(json.Number)
	if !ok {
		return 0, false
	}
	i, e := n.Int64()
	return i, e == nil
}
