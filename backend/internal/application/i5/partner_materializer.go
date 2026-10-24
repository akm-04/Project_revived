package i5

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Character Asset owns the lock band between the accepted I4/Guild suffix and
// I5 Mail/Economy suffix. CA1 reserves the band; later CA phases allocate leaf
// ranks only after their owner graphs are qualified.
const (
	CharacterAssetLockRankMin uint16 = 400
	CharacterAssetLockRankMax uint16 = 599
)

// PartnerEntityLineIdentity is stable replay identity for one semantic Grant
// line. The source semantic key intentionally excludes content revision, just
// like the canonical Grant receipt identity; the original ordinal keeps equal
// lines distinct without inventing an entity-family discriminator.
type PartnerEntityLineIdentity struct {
	GrantSemanticKey string `json:"grant_semantic_key"`
	LineOrdinal      int    `json:"line_ordinal"`
}

func (i PartnerEntityLineIdentity) Validate() error {
	if strings.TrimSpace(i.GrantSemanticKey) == "" || i.LineOrdinal < 0 {
		return errors.New("invalid partner entity line identity")
	}
	return nil
}

// PartnerEntityLine is the CA1-qualified external-materialization request for
// one existing grant.PartnerEntity line. It deliberately preserves ItemID and
// Amount without interpreting Amount or treating ItemID as a generic Hero/Pet
// family discriminator.
type PartnerEntityLine struct {
	Identity PartnerEntityLineIdentity `json:"identity"`
	ItemID   int64                     `json:"item_id"`
	Amount   int64                     `json:"amount"`
	Metadata map[string]string         `json:"metadata,omitempty"`
}

// PartnerEntityBatch is preflighted as one unit so aggregate owner constraints
// (for example roster capacity) cannot be checked independently per line.
type PartnerEntityBatch struct {
	PlayerID        identity.PlayerID   `json:"player_id"`
	ContentRevision string              `json:"content_revision"`
	Lines           []PartnerEntityLine `json:"lines"`
}

// PartnerEntityPreflight contains the complete Character lock set discovered
// before mutation. The provider cannot add locks during locked validation or
// materialization because those methods have no lock-discovery return path.
type PartnerEntityPreflight struct {
	Locks []lockkey.Key `json:"locks"`
}

// PartnerEntityMaterialization is the provider-owned typed result for one
// source line. ResultPayload may contain one or several durable owner IDs; I5
// stores and replays it but never interprets it as a generic entity identity.
type PartnerEntityMaterialization struct {
	LineOrdinal   int             `json:"line_ordinal"`
	ResultSchema  string          `json:"result_schema"`
	ResultPayload json.RawMessage `json:"result_payload"`
}

// GrantMaterialization is the durable I5 receipt envelope. Provider identity
// and revision are captured by the orchestration layer rather than trusted to
// provider payload JSON.
type GrantMaterialization struct {
	LineOrdinal      int             `json:"line_ordinal"`
	ProviderID       string          `json:"provider_id"`
	ProviderRevision string          `json:"provider_revision"`
	ResultSchema     string          `json:"result_schema"`
	ResultPayload    json.RawMessage `json:"result_payload"`
}

// PartnerEntityMaterializer is the only CA1 production-facing destination seam.
// CA1 installs no concrete production provider. CA2+ may qualify one after its
// durable owner, content rules, response projection and reconnect behavior pass
// their own lifecycle gates.
//
// Provider methods must not start/commit/rollback transactions, perform
// outbound network calls while gameplay locks are held, or mutate during
// PreflightPartnerEntityBatchTx. LockPartnerEntityKeyTx must acquire exactly the
// supplied key and may not discover another lock.
type PartnerEntityMaterializer interface {
	ProviderID() string
	ProviderRevision() string
	PreflightPartnerEntityBatchTx(context.Context, tx.Queryer, PartnerEntityBatch) (PartnerEntityPreflight, error)
	LockPartnerEntityKeyTx(context.Context, tx.Tx, lockkey.Key) error
	ValidatePartnerEntityBatchLockedTx(context.Context, tx.Tx, PartnerEntityBatch, PartnerEntityPreflight) error
	MaterializePartnerEntityBatchTx(context.Context, tx.Tx, PartnerEntityBatch, PartnerEntityPreflight, operation.Context) ([]PartnerEntityMaterialization, error)
}

type partnerEntityPrepared struct {
	Batch            PartnerEntityBatch
	Preflight        PartnerEntityPreflight
	ProviderID       string
	ProviderRevision string
}

func cloneMetadata(in map[string]string) map[string]string {
	if len(in) == 0 {
		return nil
	}
	out := make(map[string]string, len(in))
	for k, v := range in {
		out[k] = v
	}
	return out
}

func partnerEntityBatchForPlan(plan grant.Plan, contentRevision string) (PartnerEntityBatch, error) {
	if err := validateContentRevision(contentRevision); err != nil {
		return PartnerEntityBatch{}, err
	}
	semantic := plan.Source.SemanticKey()
	lines := make([]PartnerEntityLine, 0, len(plan.Lines))
	for ordinal, line := range plan.Lines {
		if line.Kind != grant.PartnerEntity {
			continue
		}
		id := PartnerEntityLineIdentity{GrantSemanticKey: semantic, LineOrdinal: ordinal}
		if err := id.Validate(); err != nil {
			return PartnerEntityBatch{}, err
		}
		lines = append(lines, PartnerEntityLine{Identity: id, ItemID: line.ItemID, Amount: line.Amount, Metadata: cloneMetadata(line.Metadata)})
	}
	if len(lines) == 0 {
		return PartnerEntityBatch{}, nil
	}
	return PartnerEntityBatch{PlayerID: plan.PlayerID, ContentRevision: contentRevision, Lines: lines}, nil
}

func validatePartnerProviderIdentity(id, revision string) error {
	if strings.TrimSpace(id) == "" || strings.TrimSpace(revision) == "" {
		return errors.New("partner entity provider identity/revision required")
	}
	return nil
}

func validateCharacterLockKey(k lockkey.Key) error {
	if k.DomainRank < CharacterAssetLockRankMin || k.DomainRank > CharacterAssetLockRankMax {
		return fmt.Errorf("partner entity lock rank %d outside Character Asset band", k.DomainRank)
	}
	// CanonicalDedup performs the complete structural key validation. Keep this
	// function focused on the CA1 ownership-band amendment.
	return nil
}

func canonicalPartnerLocks(in []lockkey.Key) ([]lockkey.Key, error) {
	if len(in) == 0 {
		return nil, errors.New("partner entity materialization requires a Character owner lock")
	}
	for _, k := range in {
		if err := validateCharacterLockKey(k); err != nil {
			return nil, err
		}
	}
	out, err := lockkey.CanonicalDedup(in)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func validatePartnerMaterializations(lines []PartnerEntityLine, got []PartnerEntityMaterialization) ([]PartnerEntityMaterialization, error) {
	if len(got) != len(lines) {
		return nil, fmt.Errorf("partner entity materialization count=%d want=%d", len(got), len(lines))
	}
	want := make(map[int]struct{}, len(lines))
	for _, line := range lines {
		want[line.Identity.LineOrdinal] = struct{}{}
	}
	seen := make(map[int]struct{}, len(got))
	out := append([]PartnerEntityMaterialization(nil), got...)
	for _, result := range out {
		if _, ok := want[result.LineOrdinal]; !ok {
			return nil, fmt.Errorf("partner entity materialization returned unknown line ordinal %d", result.LineOrdinal)
		}
		if _, dup := seen[result.LineOrdinal]; dup {
			return nil, fmt.Errorf("partner entity materialization duplicated line ordinal %d", result.LineOrdinal)
		}
		seen[result.LineOrdinal] = struct{}{}
		if strings.TrimSpace(result.ResultSchema) == "" || !json.Valid(result.ResultPayload) {
			return nil, fmt.Errorf("partner entity materialization line %d has invalid typed result", result.LineOrdinal)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].LineOrdinal < out[j].LineOrdinal })
	return out, nil
}

func (s Service) validatePartnerEntityLockedTx(ctx context.Context, t tx.Tx, pf grantPreflight) error {
	if err := s.validateSpiritLockedTx(ctx, t, pf); err != nil {
		return err
	}
	if pf.Partner == nil {
		return nil
	}
	if s.PartnerEntities == nil {
		return errors.New("partner entity materializer unavailable after lock acquisition")
	}
	if s.PartnerEntities.ProviderID() != pf.Partner.ProviderID || s.PartnerEntities.ProviderRevision() != pf.Partner.ProviderRevision {
		return errors.New("partner entity provider identity/revision changed after lock acquisition")
	}
	return s.PartnerEntities.ValidatePartnerEntityBatchLockedTx(ctx, t, pf.Partner.Batch, pf.Partner.Preflight)
}

func (s Service) materializePartnerEntityTx(ctx context.Context, t tx.Tx, pf grantPreflight, op operation.Context) ([]GrantMaterialization, error) {
	if pf.Partner == nil {
		return nil, nil
	}
	if s.PartnerEntities == nil {
		return nil, errors.New("partner entity materializer unavailable during apply")
	}
	if s.PartnerEntities.ProviderID() != pf.Partner.ProviderID || s.PartnerEntities.ProviderRevision() != pf.Partner.ProviderRevision {
		return nil, errors.New("partner entity provider identity/revision changed during apply")
	}
	got, err := s.PartnerEntities.MaterializePartnerEntityBatchTx(ctx, t, pf.Partner.Batch, pf.Partner.Preflight, op)
	if err != nil {
		return nil, err
	}
	got, err = validatePartnerMaterializations(pf.Partner.Batch.Lines, got)
	if err != nil {
		return nil, err
	}
	out := make([]GrantMaterialization, 0, len(got))
	for _, result := range got {
		out = append(out, GrantMaterialization{
			LineOrdinal:      result.LineOrdinal,
			ProviderID:       pf.Partner.ProviderID,
			ProviderRevision: pf.Partner.ProviderRevision,
			ResultSchema:     result.ResultSchema,
			ResultPayload:    append(json.RawMessage(nil), result.ResultPayload...),
		})
	}
	return out, nil
}
