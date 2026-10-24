package bootstrap

import (
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const MID1ReceiptKind = "identity.mid1.select.v1"

type MID1SemanticRequest struct {
	SessionID       string
	LogicalServerID int32
}

func MID1Fingerprint(session identity.SessionID, server identity.LogicalServerID) ([32]byte, error) {
	return receipt.FingerprintRequest(MID1SemanticRequest{SessionID: session.UUID().String(), LogicalServerID: int32(server)})
}

type MID1PostconditionEvidence struct {
	ReceiptFound               bool
	ReceiptFingerprintMatches  bool
	PlayerFound                bool
	PlayerMatchesAccountServer bool
	LiveContextFound           bool
	LiveContextMatchesTarget   bool
	// AuthoritativeNegativeProven means an operation-specific terminal/owner
	// fence proves the ambiguous MID1 transaction cannot later become visible.
	// Mere absence of receipt/player/context is not sufficient.
	AuthoritativeNegativeProven bool
}

func ReconcileMID1Evidence(e MID1PostconditionEvidence) tx.Resolution {
	if e.ReceiptFound {
		if e.ReceiptFingerprintMatches {
			return tx.Resolution{State: tx.ResolutionCommitted, Evidence: e}
		}
		return tx.Resolution{State: tx.ResolutionUnknown, Evidence: e}
	}
	if e.PlayerFound || e.LiveContextFound {
		return tx.Resolution{State: tx.ResolutionUnknown, Evidence: e}
	}
	if e.AuthoritativeNegativeProven {
		return tx.Resolution{State: tx.ResolutionAbsent, Evidence: e}
	}
	return tx.Resolution{State: tx.ResolutionUnknown, Evidence: e}
}
