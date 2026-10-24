package guildbroadcast

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

// TargetProof is an I5 owner result. It cannot be manufactured from a River
// completion or acknowledgement of a job. Its reader checks receipt and Mail.
type TargetProof struct {
	SourceID          ids.UUID
	RecipientID       identity.PlayerID
	SourceFingerprint [32]byte
	ReceiptID         ids.UUID
	State             State
	MailID            ids.UUID
	WireID            int64
}

func (p TargetProof) Validate() error {
	if p.SourceID.IsZero() || !p.RecipientID.Valid() || p.ReceiptID.IsZero() {
		return ErrSource
	}
	switch p.State {
	case Delivered:
		if p.MailID.IsZero() || p.WireID <= 0 || p.WireID > 9007199254740991 {
			return ErrSource
		}
	case RecipientGone:
		if !p.MailID.IsZero() || p.WireID != 0 {
			return ErrSource
		}
	default:
		return ErrSource
	}
	return nil
}
