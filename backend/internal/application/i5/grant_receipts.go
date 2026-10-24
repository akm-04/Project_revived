package i5

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrGrantDualReceiptConflict = errors.New("grant v2/v1 dual receipt conflict")

func receiptFingerprintForGrant(plan grant.Plan) ([32]byte, error) {
	return receipt.FingerprintRequest(plan)
}

func validateGrantReceiptFingerprint(r receipt.Receipt, fp [32]byte) error {
	if !bytes.Equal(r.RequestFingerprint[:], fp[:]) {
		return &receipt.ConflictError{Identity: r.Identity}
	}
	return nil
}

func compatibleGrantReceipts(v2, v1 receipt.Receipt) bool {
	return v2.ResultSchema == v1.ResultSchema && bytes.Equal(v2.ResultPayload, v1.ResultPayload)
}

func grantReceiptIDs(plan grant.Plan) (receipt.Identity, receipt.Identity, error) {
	return plan.ReceiptIdentities()
}

func (s Service) findGrantReceiptTx(ctx context.Context, q tx.Queryer, plan grant.Plan, fp [32]byte) (receipt.Receipt, bool, error) {
	v2id, v1id, err := grantReceiptIDs(plan)
	if err != nil {
		return receipt.Receipt{}, false, err
	}
	v2, haveV2, err := s.Receipts.FindTx(ctx, q, v2id)
	if err != nil {
		return receipt.Receipt{}, false, err
	}
	if haveV2 {
		if err := validateGrantReceiptFingerprint(v2, fp); err != nil {
			return receipt.Receipt{}, false, err
		}
	}
	v1, haveV1, err := s.Receipts.FindTx(ctx, q, v1id)
	if err != nil {
		return receipt.Receipt{}, false, err
	}
	if haveV1 {
		if err := validateGrantReceiptFingerprint(v1, fp); err != nil {
			return receipt.Receipt{}, false, err
		}
	}
	if haveV2 && haveV1 && !compatibleGrantReceipts(v2, v1) {
		return receipt.Receipt{}, false, ErrGrantDualReceiptConflict
	}
	if haveV2 {
		return v2, true, nil
	}
	if haveV1 {
		return v1, true, nil
	}
	return receipt.Receipt{}, false, nil
}

func findGrantReceipt(ctx context.Context, reader receipt.Reader, plan grant.Plan, fp [32]byte) (receipt.Receipt, bool, error) {
	if reader == nil {
		return receipt.Receipt{}, false, errors.New("nil grant receipt reader")
	}
	v2id, v1id, err := grantReceiptIDs(plan)
	if err != nil {
		return receipt.Receipt{}, false, err
	}
	v2, haveV2, err := reader.Find(ctx, v2id)
	if err != nil {
		return receipt.Receipt{}, false, err
	}
	if haveV2 {
		if err := validateGrantReceiptFingerprint(v2, fp); err != nil {
			return receipt.Receipt{}, false, err
		}
	}
	v1, haveV1, err := reader.Find(ctx, v1id)
	if err != nil {
		return receipt.Receipt{}, false, err
	}
	if haveV1 {
		if err := validateGrantReceiptFingerprint(v1, fp); err != nil {
			return receipt.Receipt{}, false, err
		}
	}
	if haveV2 && haveV1 && !compatibleGrantReceipts(v2, v1) {
		return receipt.Receipt{}, false, ErrGrantDualReceiptConflict
	}
	if haveV2 {
		return v2, true, nil
	}
	if haveV1 {
		return v1, true, nil
	}
	return receipt.Receipt{}, false, nil
}

type grantUnknownCommitResolver struct {
	Reader receipt.Reader
	Plan   grant.Plan
	FP     [32]byte
}

func (r grantUnknownCommitResolver) Resolve(ctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	got, ok, err := findGrantReceipt(ctx, r.Reader, r.Plan, r.FP)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !ok {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: got}, nil
}

func decodeGrantReceiptResult(r receipt.Receipt) (GrantResult, error) {
	switch r.ResultSchema {
	case "gxb.i5.grant.v1", "gxb.i5.grant.v2", "gxb.i5.grant.v3":
		var out GrantResult
		if err := json.Unmarshal(r.ResultPayload, &out); err != nil {
			return GrantResult{}, err
		}
		if r.ResultSchema == "gxb.i5.grant.v1" {
			out.Effects = nil
		}
		return out, nil
	default:
		return GrantResult{}, errors.New("unknown grant receipt result schema")
	}
}
