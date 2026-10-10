package guildinvite

import (
	"crypto/sha256"
	"encoding/json"
	"gxb.local/backend/v2/internal/foundation/ids"
	"time"
)

// SetWitness is a finite owner-produced aggregate of sorted source UUID and
// immutable source-fingerprint pairs. It supplies no mutable gameplay state.
type SetWitness struct {
	Count  int64
	Digest [32]byte
}

func (w SetWitness) Validate() error {
	if w.Count < 0 || w.Digest == ([32]byte{}) || w.Count == 0 && w.Digest != sha256.Sum256(nil) {
		return ErrEvidence
	}
	return nil
}

type CursorRequest struct {
	MarkerID          ids.UUID
	MarkerFingerprint [32]byte
	From, To          int64
	Complete          bool
	Covered           SetWitness
	Evidence          CoveredEvidence
}

func (v CursorRequest) Validate(m Marker) error {
	fp, e := m.Fingerprint()
	if e != nil || v.MarkerID != m.Operation.ID || v.MarkerFingerprint != fp || v.From < 0 || v.To < v.From || v.To > m.MaxIssueSerial || v.Complete && v.To != m.MaxIssueSerial || !v.Complete && (v.To == v.From || v.To == m.MaxIssueSerial) || v.Covered.Validate() != nil || v.Evidence.Validate(v.Covered) != nil {
		return ErrEvidence
	}
	return nil
}
func (v CursorRequest) Fingerprint(m Marker) ([32]byte, error) {
	if v.Validate(m) != nil {
		return [32]byte{}, ErrEvidence
	}
	raw, e := json.Marshal(v)
	if e != nil {
		return [32]byte{}, e
	}
	return sha256.Sum256(raw), nil
}

type CursorProof struct {
	Request    CursorRequest
	ReceiptID  ids.UUID
	DecisionAt time.Time
}

func (v CursorProof) Validate(m Marker) error {
	if v.Request.Validate(m) != nil || v.ReceiptID.IsZero() || v.DecisionAt.IsZero() || v.DecisionAt.Location() != time.UTC || v.DecisionAt.Before(m.DecisionAt) {
		return ErrEvidence
	}
	return nil
}
func DecodeCursorProof(raw []byte, m Marker) (CursorProof, error) {
	var v CursorProof
	if decode(raw, &v) != nil || v.Validate(m) != nil {
		return CursorProof{}, ErrEvidence
	}
	return v, nil
}
