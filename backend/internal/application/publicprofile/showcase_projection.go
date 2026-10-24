package publicprofile

import (
	"bytes"
	"encoding/json"
	"io"
)

func cloneRecord(v map[string]any) (map[string]any, error) {
	raw, e := json.Marshal(v)
	if e != nil {
		return nil, e
	}
	var out map[string]any
	d := json.NewDecoder(bytes.NewReader(raw))
	d.UseNumber()
	if e = d.Decode(&out); e != nil {
		return nil, e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return nil, ErrSelection
	}
	return out, nil
}

func cloneFacet[T any](v T) (T, error) {
	var out T
	raw, e := json.Marshal(v)
	if e != nil {
		return out, e
	}
	e = json.Unmarshal(raw, &out)
	return out, e
}
