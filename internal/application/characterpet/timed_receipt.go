package characterpet

import (
	"bytes"
	"context"
	"errors"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type timedReceiptResolver struct {
	reader receipt.Reader
	id     receipt.Identity
	fp     [32]byte
}

func (r timedReceiptResolver) ResolveTimed(ctx context.Context, _ appgeneration.TimedResolutionRequest) (tx.Resolution, error) {
	if r.reader == nil {
		return tx.Resolution{}, errors.New("character pet: nil receipt reader")
	}
	got, ok, err := r.reader.Find(ctx, r.id)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	if !bytes.Equal(got.RequestFingerprint[:], r.fp[:]) {
		return tx.Resolution{}, &receipt.ConflictError{Identity: r.id}
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: got}, nil
}
