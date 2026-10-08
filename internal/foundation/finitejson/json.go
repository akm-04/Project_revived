// Package finitejson provides bounded lossless JSON decoding at typed edges.
package finitejson

import (
	"encoding/json"
	"errors"
	"io"
	"math/big"
	"strconv"
	"strings"
	"unicode/utf8"
)

var ErrMalformed = errors.New("malformed finite JSON")

// Bound lexical exponent work before exact rational validation (including underflow).
func ExactInteger(n json.Number) (int64, error) {
	text := string(n)
	if len(text) > 64 {
		return 0, ErrMalformed
	}
	if i := strings.IndexAny(text, "eE"); i >= 0 {
		e, err := strconv.Atoi(text[i+1:])
		if err != nil || e < -400 || e > 400 {
			return 0, ErrMalformed
		}
	}
	v, ok := new(big.Rat).SetString(text)
	if !ok || !v.IsInt() || !v.Num().IsInt64() {
		return 0, ErrMalformed
	}
	i := v.Num().Int64()
	if i < -9007199254740991 || i > 9007199254740991 {
		return 0, ErrMalformed
	}
	return i, nil
}
func Decode(text string, byteBudget, depthBudget, nodeBudget, keyBudget int) (map[string]any, error) {
	bad := ErrMalformed
	if text == "" || len(text) > byteBudget || !utf8.ValidString(text) || !validStructuredEscapes(text) {
		return nil, bad
	}
	d := json.NewDecoder(strings.NewReader(text))
	d.UseNumber()
	keys, values := 0, 0
	var read func(int) (any, error)
	read = func(depth int) (any, error) {
		values++
		if depth > depthBudget || values > nodeBudget {
			return nil, bad
		}
		token, e := d.Token()
		if e != nil {
			return nil, bad
		}
		switch v := token.(type) {
		case json.Delim:
			switch v {
			case '{':
				m := map[string]any{}
				for d.More() {
					k, e := d.Token()
					name, ok := k.(string)
					if e != nil || !ok {
						return nil, bad
					}
					if _, exists := m[name]; exists {
						return nil, bad
					}
					keys++
					if keys > keyBudget {
						return nil, bad
					}
					x, e := read(depth + 1)
					if e != nil {
						return nil, e
					}
					m[name] = x
				}
				end, e := d.Token()
				if e != nil || end != json.Delim('}') {
					return nil, bad
				}
				return m, nil
			case '[':
				a := []any{}
				for d.More() {
					if len(a) >= 3 {
						return nil, bad
					}
					x, e := read(depth + 1)
					if e != nil {
						return nil, e
					}
					a = append(a, x)
				}
				end, e := d.Token()
				if e != nil || end != json.Delim(']') {
					return nil, bad
				}
				return a, nil
			}
		case json.Number:
			return ExactInteger(v)
		case string:
			if !utf8.ValidString(v) {
				return nil, bad
			}
			return v, nil
		case bool:
			return v, nil
		}
		return nil, bad
	}
	v, e := read(1)
	if e != nil {
		return nil, e
	}
	var trailing any
	if d.Decode(&trailing) != io.EOF {
		return nil, bad
	}
	m, ok := v.(map[string]any)
	if !ok {
		return nil, bad
	}
	return m, nil
}
func ValidateUnicodeEscapes(s string) bool { return utf8.ValidString(s) && validStructuredEscapes(s) }
func validStructuredEscapes(s string) bool {
	quoted := false
	for i := 0; i < len(s); i++ {
		if s[i] == '"' {
			quoted = !quoted
			continue
		}
		if !quoted || s[i] != '\\' {
			continue
		}
		i++
		if i >= len(s) {
			return false
		}
		if s[i] != 'u' {
			continue
		}
		if i+4 >= len(s) {
			return false
		}
		v, e := strconv.ParseUint(s[i+1:i+5], 16, 16)
		if e != nil {
			return false
		}
		i += 4
		if v >= 0xDC00 && v <= 0xDFFF {
			return false
		}
		if v >= 0xD800 && v <= 0xDBFF {
			if i+6 >= len(s) || s[i+1:i+3] != `\u` {
				return false
			}
			low, e := strconv.ParseUint(s[i+3:i+7], 16, 16)
			if e != nil || low < 0xDC00 || low > 0xDFFF {
				return false
			}
			i += 6
		}
	}
	return true
}
