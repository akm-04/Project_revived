package grant

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
)

type LineKind string

const (
	ScalarCurrency    LineKind = "SCALAR_CURRENCY"
	Temporal          LineKind = "TEMPORAL"
	StackItem         LineKind = "STACK_ITEM"
	PlayerExp         LineKind = "PLAYER_EXP"
	PartnerEntity     LineKind = "PARTNER_ENTITY"
	SpecializedDomain LineKind = "SPECIALIZED_DOMAIN"
)

type SourceIdentity struct {
	Domain        string
	Operation     string
	BusinessKey   string
	Occurrence    string
	PolicyVersion string
}

func (s SourceIdentity) Validate() error {
	if strings.TrimSpace(s.Domain) == "" || strings.TrimSpace(s.Operation) == "" || strings.TrimSpace(s.BusinessKey) == "" || strings.TrimSpace(s.PolicyVersion) == "" {
		return errors.New("incomplete grant source identity")
	}
	return nil
}

// SemanticKey is the canonical R4 v2 entitlement identity. Content/policy
// revision is deliberately excluded: activation of a new immutable content
// revision cannot manufacture a second business entitlement for the same
// source occurrence.
func (s SourceIdentity) SemanticKey() string {
	parts := []string{s.Domain, s.Operation, s.BusinessKey, s.Occurrence}
	h := sha256.Sum256([]byte(strings.Join(parts, "\x00")))
	return hex.EncodeToString(h[:])
}

// LegacySemanticKeyV1 reconstructs the Pass447-Pass474 identity exactly for
// receipt replay. New settlements never write this identity.
func (s SourceIdentity) LegacySemanticKeyV1() string {
	parts := []string{s.Domain, s.Operation, s.BusinessKey, s.Occurrence, s.PolicyVersion}
	h := sha256.Sum256([]byte(strings.Join(parts, "\x00")))
	return hex.EncodeToString(h[:])
}

type Line struct {
	Kind        LineKind
	ResourceKey string
	ItemID      int64
	Amount      int64
	Domain      string
	Metadata    map[string]string
}

func (l Line) Validate() error {
	if l.Amount <= 0 {
		return errors.New("grant amount must be positive")
	}
	switch l.Kind {
	case ScalarCurrency, Temporal:
		if strings.TrimSpace(l.ResourceKey) == "" || l.ItemID != 0 || l.Domain != "" {
			return errors.New("invalid fungible grant line")
		}
	case StackItem:
		if l.ItemID <= 0 || l.ResourceKey != "" || l.Domain != "" {
			return errors.New("invalid stack-item grant line")
		}
	case PlayerExp:
		if l.ResourceKey != "" || l.ItemID != 0 || l.Domain != "" {
			return errors.New("invalid player-exp grant line")
		}
	case PartnerEntity:
		if l.ItemID <= 0 || l.ResourceKey != "" || l.Domain != "" {
			return errors.New("invalid partner/entity grant line")
		}
	case SpecializedDomain:
		if strings.TrimSpace(l.Domain) == "" {
			return errors.New("specialized grant requires owning domain")
		}
	default:
		return errors.New("unknown grant line kind")
	}
	return nil
}

type Plan struct {
	PlayerID identity.PlayerID
	Source   SourceIdentity
	Lines    []Line
}

func (p Plan) Validate() error {
	if !p.PlayerID.Valid() {
		return errors.New("grant player required")
	}
	if err := p.Source.Validate(); err != nil {
		return err
	}
	if len(p.Lines) == 0 {
		return errors.New("grant plan has no lines")
	}
	for i, l := range p.Lines {
		if err := l.Validate(); err != nil {
			return fmt.Errorf("grant line %d: %w", i, err)
		}
	}
	return nil
}
func (p Plan) ReceiptIdentity() (receipt.Identity, error) {
	if err := p.Validate(); err != nil {
		return receipt.Identity{}, err
	}
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(p.PlayerID), 10), Domain: "grant", Operation: "settle", SemanticKey: p.Source.SemanticKey()}, nil
}

func (p Plan) LegacyReceiptIdentityV1() (receipt.Identity, error) {
	if err := p.Validate(); err != nil {
		return receipt.Identity{}, err
	}
	return receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(p.PlayerID), 10), Domain: "grant", Operation: "settle", SemanticKey: p.Source.LegacySemanticKeyV1()}, nil
}

// ReceiptIdentities returns canonical v2 first, followed by reconstructable
// legacy v1, matching the frozen R4 compatibility lookup order.
func (p Plan) ReceiptIdentities() (receipt.Identity, receipt.Identity, error) {
	v2, err := p.ReceiptIdentity()
	if err != nil {
		return receipt.Identity{}, receipt.Identity{}, err
	}
	v1, err := p.LegacyReceiptIdentityV1()
	if err != nil {
		return receipt.Identity{}, receipt.Identity{}, err
	}
	return v2, v1, nil
}

// OverflowMailSourceKey is the canonical v2 deterministic source identity. The
// explicit version prefix prevents a silent reinterpretation of historical
// Pass447-Pass474 overflow-mail keys.
func (p Plan) OverflowMailSourceKey(itemID int64, lineOrdinal int) (string, error) {
	if err := p.Validate(); err != nil {
		return "", err
	}
	if itemID <= 0 || lineOrdinal < 0 || lineOrdinal >= len(p.Lines) {
		return "", errors.New("invalid overflow line identity")
	}
	return fmt.Sprintf("grant-overflow:v2:%s:%d:%d", p.Source.SemanticKey(), itemID, lineOrdinal), nil
}

// LegacyOverflowMailSourceKeyV1 reconstructs the exact pre-R4D derivation for
// compatibility diagnostics/replay. New overflow mail never uses this key.
func (p Plan) LegacyOverflowMailSourceKeyV1(itemID int64, lineOrdinal int) (string, error) {
	if err := p.Validate(); err != nil {
		return "", err
	}
	if itemID <= 0 || lineOrdinal < 0 || lineOrdinal >= len(p.Lines) {
		return "", errors.New("invalid overflow line identity")
	}
	return fmt.Sprintf("grant-overflow:%s:%d:%d", p.Source.LegacySemanticKeyV1(), itemID, lineOrdinal), nil
}
