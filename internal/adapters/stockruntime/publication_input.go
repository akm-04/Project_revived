package stockruntime

import (
	"encoding/json"
	"fmt"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"io"
)

// DecodePublicationInput accepts a single typed published input, not an operator workflow.
func DecodePublicationInput(r io.Reader) (pub.Catalog, error) {
	var c pub.Catalog
	d := json.NewDecoder(r)
	d.DisallowUnknownFields()
	if e := d.Decode(&c); e != nil {
		return c, e
	}
	var extra any
	if e := d.Decode(&extra); e != io.EOF {
		return c, fmt.Errorf("trailing publication input")
	}
	for _, s := range c.Sets {
		if e := s.Validate(); e != nil {
			return c, e
		}
	}
	return c, nil
}
