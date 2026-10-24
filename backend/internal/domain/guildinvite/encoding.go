package guildinvite

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"io"
)

// JSONB may reorder object fields, but must not add or erase evidence. The
// canonical typed fingerprint is checked after a strict complete decode.
func decode(raw []byte, v any) error {
	d := json.NewDecoder(bytes.NewReader(raw))
	d.DisallowUnknownFields()
	if e := d.Decode(v); e != nil {
		return ErrEvidence
	}
	if e := d.Decode(new(any)); e != io.EOF {
		return ErrEvidence
	}
	return nil
}

func DecodeIssue(raw []byte, fingerprint string) (Issue, error) {
	var v Issue
	if decode(raw, &v) != nil {
		return v, ErrEvidence
	}
	fp, e := v.Fingerprint()
	if e != nil || hex.EncodeToString(fp[:]) != fingerprint {
		return Issue{}, ErrEvidence
	}
	return v, nil
}

func DecodeMarker(raw []byte, fingerprint string) (Marker, error) {
	var v Marker
	if decode(raw, &v) != nil {
		return v, ErrEvidence
	}
	fp, e := v.Fingerprint()
	if e != nil || hex.EncodeToString(fp[:]) != fingerprint {
		return Marker{}, ErrEvidence
	}
	return v, nil
}

func DecodeTargetProof(raw []byte) (TargetProof, error) {
	var v TargetProof
	if decode(raw, &v) != nil || v.Validate() != nil {
		return TargetProof{}, ErrEvidence
	}
	return v, nil
}

func DecodeInvalidationProof(raw []byte) (InvalidationProof, error) {
	var v InvalidationProof
	if decode(raw, &v) != nil || v.Validate() != nil {
		return InvalidationProof{}, ErrEvidence
	}
	return v, nil
}
