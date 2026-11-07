package socialinvite

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"strings"

	"gxb.local/backend/v2/internal/foundation/tx"
)

// Settings is the D476 validated override/off hook. There is no operator
// endpoint before I11; an absent or invalid payload keeps source policy.
type Settings interface {
	TuningTx(context.Context, tx.Queryer) (json.RawMessage, error)
}

type inviteTuning struct {
	Version       int    `json:"version"`
	Revision      string `json:"revision"`
	InvitationOff bool   `json:"invitation_off"`
}

func invitationOff(raw json.RawMessage) bool {
	if len(raw) == 0 {
		return false
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	var settings inviteTuning
	if decoder.Decode(&settings) != nil {
		return false
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return false
	}
	if settings.Version != 1 || strings.TrimSpace(settings.Revision) == "" || len(settings.Revision) > 128 {
		return false
	}
	return settings.InvitationOff
}
