package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strings"
)

// SpiritLineIdentity is stable replay identity for one semantic Grant
// line. The source semantic key intentionally excludes content revision, just
// like the canonical Grant receipt identity; the original ordinal keeps equal
// lines distinct without reusing PartnerEntity item identity.
type SpiritLineIdentity struct {
	GrantSemanticKey string `json:"grant_semantic_key"`
	LineOrdinal      int    `json:"line_ordinal"`
}

func (i SpiritLineIdentity) Validate() error {
	if strings.TrimSpace(i.GrantSemanticKey) == "" || i.LineOrdinal < 0 {
		return errors.New("invalid Spirit line identity")
	}
	return nil
}

// SpiritLine is the I7C-2H-qualified external-materialization request for
// one existing grant.SpecializedDomain line. It deliberately preserves ItemID and
// Amount without interpreting Amount or treating ItemID as a generic Hero/Pet
// family discriminator.
type SpiritLine struct {
	Identity SpiritLineIdentity `json:"identity"`
	ItemID   int64              `json:"item_id"`
	Amount   int64              `json:"amount"`
	Metadata map[string]string  `json:"metadata,omitempty"`
}

// SpiritBatch is preflighted as one unit so aggregate owner constraints
// (for example roster capacity) cannot be checked independently per line.
type SpiritBatch struct {
	PlayerID        identity.PlayerID `json:"player_id"`
	ContentRevision string            `json:"content_revision"`
	Lines           []SpiritLine      `json:"lines"`
}

// SpiritPreflight contains the complete Character lock set discovered
// before mutation. The provider cannot add locks during locked validation or
// materialization because those methods have no lock-discovery return path.
type SpiritPreflight struct {
	Locks []lockkey.Key `json:"locks"`
}

// SpiritMaterialization is the provider-owned typed result for one
// source line. ResultPayload may contain one or several durable owner IDs; I5
// stores and replays it but never interprets it as a generic entity identity.
type SpiritMaterialization struct {
	LineOrdinal   int             `json:"line_ordinal"`
	ResultSchema  string          `json:"result_schema"`
	ResultPayload json.RawMessage `json:"result_payload"`
}

type SpiritMaterializer interface {
	ProviderID() string
	ProviderRevision() string
	PreflightSpiritBatchTx(context.Context, tx.Queryer, SpiritBatch) (SpiritPreflight, error)
	LockSpiritKeyTx(context.Context, tx.Tx, lockkey.Key) error
	ValidateSpiritBatchLockedTx(context.Context, tx.Tx, SpiritBatch, SpiritPreflight) error
	MaterializeSpiritBatchTx(context.Context, tx.Tx, SpiritBatch, SpiritPreflight, operation.Context) ([]SpiritMaterialization, error)
}
type spiritPrepared struct {
	Batch                        SpiritBatch
	Preflight                    SpiritPreflight
	ProviderID, ProviderRevision string
}

func spiritBatchForPlan(plan grant.Plan, contentRevision string) (SpiritBatch, error) {
	if err := validateContentRevision(contentRevision); err != nil {
		return SpiritBatch{}, err
	}
	semantic := plan.Source.SemanticKey()
	lines := make([]SpiritLine, 0, len(plan.Lines))
	for ordinal, line := range plan.Lines {
		if line.Kind != grant.SpecializedDomain || line.Domain != "spirit" {
			continue
		}
		id := SpiritLineIdentity{GrantSemanticKey: semantic, LineOrdinal: ordinal}
		if err := id.Validate(); err != nil {
			return SpiritBatch{}, err
		}
		lines = append(lines, SpiritLine{Identity: id, ItemID: line.ItemID, Amount: line.Amount, Metadata: cloneMetadata(line.Metadata)})
	}
	if len(lines) == 0 {
		return SpiritBatch{}, nil
	}
	return SpiritBatch{PlayerID: plan.PlayerID, ContentRevision: contentRevision, Lines: lines}, nil
}

func validateSpiritMaterializations(lines []SpiritLine, got []SpiritMaterialization) ([]SpiritMaterialization, error) {
	if len(got) != len(lines) {
		return nil, fmt.Errorf("Spirit materialization count=%d want=%d", len(got), len(lines))
	}
	want := make(map[int]struct{}, len(lines))
	for _, line := range lines {
		want[line.Identity.LineOrdinal] = struct{}{}
	}
	seen := make(map[int]struct{}, len(got))
	out := append([]SpiritMaterialization(nil), got...)
	for _, result := range out {
		if _, ok := want[result.LineOrdinal]; !ok {
			return nil, fmt.Errorf("Spirit materialization returned unknown line ordinal %d", result.LineOrdinal)
		}
		if _, dup := seen[result.LineOrdinal]; dup {
			return nil, fmt.Errorf("Spirit materialization duplicated line ordinal %d", result.LineOrdinal)
		}
		seen[result.LineOrdinal] = struct{}{}
		if strings.TrimSpace(result.ResultSchema) == "" || !json.Valid(result.ResultPayload) {
			return nil, fmt.Errorf("Spirit materialization line %d has invalid typed result", result.LineOrdinal)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].LineOrdinal < out[j].LineOrdinal })
	return out, nil
}

func (s Service) validateSpiritLockedTx(ctx context.Context, t tx.Tx, pf grantPreflight) error {
	if pf.Spirit == nil {
		return nil
	}
	if s.Spirits == nil {
		return errors.New("Spirit materializer unavailable after lock acquisition")
	}
	if s.Spirits.ProviderID() != pf.Spirit.ProviderID || s.Spirits.ProviderRevision() != pf.Spirit.ProviderRevision {
		return errors.New("Spirit provider identity/revision changed after lock acquisition")
	}
	return s.Spirits.ValidateSpiritBatchLockedTx(ctx, t, pf.Spirit.Batch, pf.Spirit.Preflight)
}

func (s Service) materializeSpiritTx(ctx context.Context, t tx.Tx, pf grantPreflight, op operation.Context) ([]GrantMaterialization, error) {
	if pf.Spirit == nil {
		return nil, nil
	}
	if s.Spirits == nil {
		return nil, errors.New("Spirit materializer unavailable during apply")
	}
	if s.Spirits.ProviderID() != pf.Spirit.ProviderID || s.Spirits.ProviderRevision() != pf.Spirit.ProviderRevision {
		return nil, errors.New("Spirit provider identity/revision changed during apply")
	}
	got, err := s.Spirits.MaterializeSpiritBatchTx(ctx, t, pf.Spirit.Batch, pf.Spirit.Preflight, op)
	if err != nil {
		return nil, err
	}
	got, err = validateSpiritMaterializations(pf.Spirit.Batch.Lines, got)
	if err != nil {
		return nil, err
	}
	out := make([]GrantMaterialization, 0, len(got))
	for _, result := range got {
		out = append(out, GrantMaterialization{
			LineOrdinal:      result.LineOrdinal,
			ProviderID:       pf.Spirit.ProviderID,
			ProviderRevision: pf.Spirit.ProviderRevision,
			ResultSchema:     result.ResultSchema,
			ResultPayload:    append(json.RawMessage(nil), result.ResultPayload...),
		})
	}
	return out, nil
}
