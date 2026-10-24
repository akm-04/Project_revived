package generaldm

import (
	"encoding/json"
	"gxb.local/backend/v2/internal/foundation/finitejson"
	"gxb.local/backend/v2/internal/foundation/ids"
	"io"
	"strings"
)

type Reference struct {
	ID      string `json:"operation_id"`
	Version int64  `json:"version"`
}

func (r Reference) Encode() (string, error) {
	if _, e := ids.ParseUUID(r.ID); e != nil || r.Version < 1 {
		return "", ErrInvalid
	}
	b, e := json.Marshal(r)
	return string(b), e
}
func DecodeReference(raw string) (Reference, error) {
	if _, e := finitejson.Decode(raw, 256, 2, 4, 2); e != nil {
		return Reference{}, ErrInvalid
	}
	d := json.NewDecoder(strings.NewReader(raw))
	d.DisallowUnknownFields()
	var r Reference
	if d.Decode(&r) != nil {
		return r, ErrInvalid
	}
	var more any
	if d.Decode(&more) != io.EOF {
		return r, ErrInvalid
	}
	if _, e := r.Encode(); e != nil {
		return r, e
	}
	return r, nil
}
