package httpedge

import (
	"bytes"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"io"
	"unicode/utf8"
)

func socialMID(mid uint16) bool {
	return mid == 513 || mid == 515 || mid >= 176 && mid <= 190
}

func strictRawMID(mid uint16) bool {
	return mid == 1830 || mid == 1835 || mid == 1836 || mid == 1839 || mid == 1841 || mid == 1842 || socialMID(mid) || mid == 588 || mid == 1832 || mid == 1838 || mid == 1831 || mid == 1833 || mid == 1834
}

// Finite selected routes require raw duplicate detection: decoded maps have already lost it.
// Inspect every top-level MID declaration so a last-wins MID cannot evade scope.
func validateSocialRaw(raw []byte, selected bool, depthBudget, nodeBudget int) error {
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	nodes := 0
	duplicate := false
	var walk func(int, bool) (any, error)
	walk = func(depth int, top bool) (any, error) {
		nodes++
		if nodes > nodeBudget || depth > depthBudget {
			return nil, errJSONBudget
		}
		tok, e := d.Token()
		if e != nil {
			return nil, e
		}
		delim, ok := tok.(json.Delim)
		if !ok {
			return tok, nil
		}
		switch delim {
		case '{':
			keys := map[string]bool{}
			for d.More() {
				k, e := d.Token()
				if e != nil {
					return nil, e
				}
				key, ok := k.(string)
				if !ok {
					return nil, errors.New("key")
				}
				if keys[key] {
					duplicate = true
				}
				keys[key] = true
				v, e := walk(depth+1, false)
				if top && key == "mid" {
					if n, ok := numericMID(v); ok && strictRawMID(n) {
						selected = true
					}
				}
				if e != nil {
					return nil, e
				}
			}
			end, e := d.Token()
			if e != nil || end != json.Delim('}') {
				return nil, errors.New("object")
			}
		case '[':
			for d.More() {
				if _, e := walk(depth+1, false); e != nil {
					return nil, e
				}
			}
			end, e := d.Token()
			if e != nil || end != json.Delim(']') {
				return nil, errors.New("array")
			}
		default:
			return nil, errors.New("delimiter")
		}
		return nil, nil
	}
	_, e := walk(1, true)
	if e == nil {
		if _, extra := d.Token(); extra != io.EOF {
			e = errors.New("trailing JSON")
		}
	}
	if selected {
		if e != nil {
			return e
		}
		if duplicate || !utf8.Valid(raw) || !finitejson.ValidateUnicodeEscapes(string(raw)) {
			return errors.New("ambiguous Social JSON")
		}
	}
	return nil
}
