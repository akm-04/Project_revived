package economy

import (
	"errors"
	"math"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

var (
	ErrInsufficientBalance   = errors.New("insufficient canonical balance")
	ErrUnknownResource       = errors.New("unknown or wrong-class resource")
	ErrStackCapacity         = errors.New("stack credit exceeds capacity without mail overflow policy")
	ErrInvalidTemporalPolicy = errors.New("invalid temporal resource policy")
)

type ResourceClass uint8

const (
	ScalarWallet ResourceClass = iota + 1
	TemporalResource
	StackItem
	PlayerProgression
	GeneratedOrUnique
	DomainGuarded
	CommerceVIP
)

type ScalarBalance struct {
	PlayerID     identity.PlayerID
	ResourceKey  string
	Amount       int64
	StateVersion int64
	UpdatedAt    time.Time
}

func (b ScalarBalance) Validate() error {
	if !b.PlayerID.Valid() || b.ResourceKey == "" || b.Amount < 0 || b.StateVersion <= 0 || b.UpdatedAt.IsZero() {
		return errors.New("invalid scalar balance")
	}
	return nil
}
func (b ScalarBalance) Credit(amount int64, now time.Time) (ScalarBalance, error) {
	if err := b.Validate(); err != nil {
		return ScalarBalance{}, err
	}
	if amount <= 0 || now.IsZero() {
		return ScalarBalance{}, errors.New("credit must be positive")
	}
	if amount > math.MaxInt64-b.Amount {
		return ScalarBalance{}, errors.New("scalar balance overflow")
	}
	b.Amount += amount
	b.StateVersion++
	b.UpdatedAt = now.UTC()
	return b, nil
}
func (b ScalarBalance) Debit(amount int64, now time.Time) (ScalarBalance, error) {
	if err := b.Validate(); err != nil {
		return ScalarBalance{}, err
	}
	if amount <= 0 || now.IsZero() {
		return ScalarBalance{}, errors.New("debit must be positive")
	}
	if b.Amount < amount {
		return ScalarBalance{}, ErrInsufficientBalance
	}
	b.Amount -= amount
	b.StateVersion++
	b.UpdatedAt = now.UTC()
	return b, nil
}

type TemporalPolicy struct {
	Version                           string
	RegenEvery                        time.Duration
	RegenAmount                       int64
	NaturalCap                        int64
	AllowExplicitGrantAboveNaturalCap bool
}

func (p TemporalPolicy) Validate() error {
	if p.Version == "" || p.RegenEvery <= 0 || p.RegenAmount <= 0 || p.NaturalCap < 0 {
		return ErrInvalidTemporalPolicy
	}
	return nil
}

type TemporalState struct {
	PlayerID     identity.PlayerID
	ResourceKey  string
	StoredAmount int64
	// RegenAnchorAt is the stock last-regeneration anchor. nil is the canonical
	// paused/full sentinel and projects to numeric 0 on the stock wire.
	RegenAnchorAt   *time.Time
	PolicyVersion   string
	ContentRevision string
	StateVersion    int64
	UpdatedAt       time.Time
}

func (s TemporalState) Validate() error {
	if !s.PlayerID.Valid() || s.ResourceKey == "" || s.StoredAmount < 0 || s.PolicyVersion == "" || s.StateVersion <= 0 || s.UpdatedAt.IsZero() {
		return errors.New("invalid temporal state")
	}
	if s.RegenAnchorAt != nil && s.RegenAnchorAt.IsZero() {
		return errors.New("invalid temporal regen anchor")
	}
	return nil
}

type MaterializedTemporal struct {
	State  TemporalState
	Amount int64
}

func anchorUTC(t time.Time) *time.Time {
	u := t.UTC()
	return &u
}

// materializeTemporal applies stock last-anchor semantics without advancing
// state_version. Callers that compose materialization with another owner
// mutation can therefore persist one canonical version step for the whole
// settlement.
func materializeTemporal(s TemporalState, now time.Time, p TemporalPolicy) (TemporalState, bool, error) {
	if err := s.Validate(); err != nil {
		return TemporalState{}, false, err
	}
	if err := p.Validate(); err != nil {
		return TemporalState{}, false, err
	}
	if s.PolicyVersion != p.Version {
		return TemporalState{}, false, errors.New("temporal policy version mismatch")
	}
	if now.IsZero() {
		return TemporalState{}, false, errors.New("authoritative time required")
	}
	now = now.UTC()
	changed := false

	// At/above natural cap regeneration is paused. Imported over-cap balances
	// are preserved; the canonical repair is only the anchor sentinel.
	if s.StoredAmount >= p.NaturalCap {
		if s.RegenAnchorAt != nil {
			s.RegenAnchorAt = nil
			changed = true
		}
		return s, changed, nil
	}

	// A paused state below cap has no trustworthy elapsed interval. R5
	// compatibility rearms from the stable operation time without catch-up.
	if s.RegenAnchorAt == nil {
		s.RegenAnchorAt = anchorUTC(now)
		return s, true, nil
	}

	anchor := s.RegenAnchorAt.UTC()
	// Clock rollback/future imported anchor: preserve balance and rebase to the
	// stable operation time; never mint negative/retroactive regeneration.
	if now.Before(anchor) {
		s.RegenAnchorAt = anchorUTC(now)
		return s, true, nil
	}

	steps := int64(now.Sub(anchor) / p.RegenEvery)
	if steps <= 0 {
		return s, changed, nil
	}
	maxSteps := (p.NaturalCap - s.StoredAmount + p.RegenAmount - 1) / p.RegenAmount
	if steps > maxSteps {
		steps = maxSteps
	}
	if steps <= 0 {
		return s, changed, nil
	}
	if steps > math.MaxInt64/p.RegenAmount {
		return TemporalState{}, false, errors.New("temporal regeneration overflow")
	}
	add := steps * p.RegenAmount
	if add > math.MaxInt64-s.StoredAmount {
		return TemporalState{}, false, errors.New("temporal regeneration overflow")
	}
	s.StoredAmount += add
	if s.StoredAmount >= p.NaturalCap {
		if s.StoredAmount > p.NaturalCap {
			s.StoredAmount = p.NaturalCap
		}
		s.RegenAnchorAt = nil
	} else {
		nextAnchor := anchor.Add(time.Duration(steps) * p.RegenEvery)
		s.RegenAnchorAt = anchorUTC(nextAnchor)
	}
	return s, true, nil
}

// Materialize uses only the supplied authoritative time. It never reads device
// or process wall clock by itself. If canonical state changes, the owner version
// advances exactly once.
func (s TemporalState) Materialize(now time.Time, p TemporalPolicy) (MaterializedTemporal, error) {
	next, changed, err := materializeTemporal(s, now, p)
	if err != nil {
		return MaterializedTemporal{}, err
	}
	if changed {
		next.StateVersion++
		next.UpdatedAt = now.UTC()
	}
	return MaterializedTemporal{State: next, Amount: next.StoredAmount}, nil
}

func (s TemporalState) Credit(amount int64, now time.Time, p TemporalPolicy) (TemporalState, error) {
	if amount <= 0 {
		return TemporalState{}, errors.New("temporal credit must be positive")
	}
	m, _, err := materializeTemporal(s, now, p)
	if err != nil {
		return TemporalState{}, err
	}
	if amount > math.MaxInt64-m.StoredAmount {
		return TemporalState{}, errors.New("temporal balance overflow")
	}
	next := m.StoredAmount + amount
	if next > p.NaturalCap && !p.AllowExplicitGrantAboveNaturalCap {
		return TemporalState{}, ErrStackCapacity
	}
	m.StoredAmount = next
	if m.StoredAmount >= p.NaturalCap {
		m.RegenAnchorAt = nil
	} else if m.RegenAnchorAt == nil {
		m.RegenAnchorAt = anchorUTC(now)
	}
	m.StateVersion = s.StateVersion + 1
	m.UpdatedAt = now.UTC()
	return m, nil
}

func (s TemporalState) Debit(amount int64, now time.Time, p TemporalPolicy) (TemporalState, error) {
	if amount <= 0 {
		return TemporalState{}, errors.New("temporal debit must be positive")
	}
	m, _, err := materializeTemporal(s, now, p)
	if err != nil {
		return TemporalState{}, err
	}
	if m.StoredAmount < amount {
		return TemporalState{}, ErrInsufficientBalance
	}
	m.StoredAmount -= amount
	if m.StoredAmount < p.NaturalCap && m.RegenAnchorAt == nil {
		m.RegenAnchorAt = anchorUTC(now)
	}
	m.StateVersion = s.StateVersion + 1
	m.UpdatedAt = now.UTC()
	return m, nil
}

// ApplyLevelTransition composes old-cap materialization, a departed-level
// Energy award, and final-cap normalization as one canonical temporal-owner
// mutation. Explicit level-up awards may exceed the final natural cap.
func (s TemporalState) ApplyLevelTransition(award int64, now time.Time, oldPolicy, newPolicy TemporalPolicy) (TemporalState, error) {
	if award < 0 {
		return TemporalState{}, errors.New("level transition energy award must be non-negative")
	}
	if err := newPolicy.Validate(); err != nil {
		return TemporalState{}, err
	}
	m, changed, err := materializeTemporal(s, now, oldPolicy)
	if err != nil {
		return TemporalState{}, err
	}
	if award > math.MaxInt64-m.StoredAmount {
		return TemporalState{}, errors.New("level transition energy overflow")
	}
	if award > 0 {
		m.StoredAmount += award
		changed = true
	}
	if m.PolicyVersion != newPolicy.Version {
		m.PolicyVersion = newPolicy.Version
		changed = true
	}
	if m.StoredAmount >= newPolicy.NaturalCap {
		if m.RegenAnchorAt != nil {
			m.RegenAnchorAt = nil
			changed = true
		}
	} else if m.RegenAnchorAt == nil {
		m.RegenAnchorAt = anchorUTC(now)
		changed = true
	}
	if changed {
		m.StateVersion = s.StateVersion + 1
		m.UpdatedAt = now.UTC()
	} else {
		m.StateVersion = s.StateVersion
		m.UpdatedAt = s.UpdatedAt
	}
	return m, nil
}

// RebindLegacyPolicy performs the explicit R5 legacy->immutable temporal
// transition at a known operation boundary. The legacy policy is materialized
// up to now first; the new policy is never applied retroactively. If the regen
// cadence changes, the new cadence begins at now. A qualified running remainder
// is preserved only when cadence and regen amount are unchanged.
func (s TemporalState) RebindLegacyPolicy(contentRevision string, now time.Time, oldPolicy, newPolicy TemporalPolicy) (TemporalState, error) {
	if s.ContentRevision != "" {
		return TemporalState{}, errors.New("temporal state is not legacy")
	}
	if contentRevision == "" || now.IsZero() {
		return TemporalState{}, errors.New("temporal rebind requires exact content revision and authoritative time")
	}
	if err := oldPolicy.Validate(); err != nil {
		return TemporalState{}, err
	}
	if err := newPolicy.Validate(); err != nil {
		return TemporalState{}, err
	}
	if s.PolicyVersion != oldPolicy.Version {
		return TemporalState{}, errors.New("legacy temporal policy version mismatch")
	}
	if s.StateVersion == math.MaxInt64 {
		return TemporalState{}, errors.New("temporal state version overflow")
	}
	now = now.UTC()
	m, _, err := materializeTemporal(s, now, oldPolicy)
	if err != nil {
		return TemporalState{}, err
	}

	// The migration boundary is exactly now. Existing running fractional
	// progress remains qualified only when the cadence itself is unchanged.
	if m.StoredAmount >= newPolicy.NaturalCap {
		m.RegenAnchorAt = nil
	} else if m.RegenAnchorAt == nil || oldPolicy.RegenEvery != newPolicy.RegenEvery || oldPolicy.RegenAmount != newPolicy.RegenAmount {
		m.RegenAnchorAt = anchorUTC(now)
	}
	m.PolicyVersion = newPolicy.Version
	m.ContentRevision = contentRevision
	m.StateVersion = s.StateVersion + 1
	m.UpdatedAt = now
	return m, nil
}

type StackDefinition struct {
	ItemID         int64
	StackCap       int64
	OverflowToMail bool
}

func (d StackDefinition) Validate() error {
	if d.ItemID <= 0 || d.StackCap <= 0 {
		return errors.New("invalid stack definition")
	}
	return nil
}

type StackState struct {
	PlayerID              identity.PlayerID
	ItemID                int64
	Quantity              int64
	StateVersion          int64
	AcquiredAt, UpdatedAt time.Time
}

func (s StackState) Validate() error {
	if !s.PlayerID.Valid() || s.ItemID <= 0 || s.Quantity < 0 || s.StateVersion <= 0 || s.AcquiredAt.IsZero() || s.UpdatedAt.IsZero() {
		return errors.New("invalid stack state")
	}
	return nil
}

type StackCreditResult struct {
	State    StackState
	Fit      int64
	Overflow int64
}

func (s StackState) PlanCredit(amount int64, def StackDefinition, now time.Time) (StackCreditResult, error) {
	if err := s.Validate(); err != nil {
		return StackCreditResult{}, err
	}
	if err := def.Validate(); err != nil {
		return StackCreditResult{}, err
	}
	if s.ItemID != def.ItemID {
		return StackCreditResult{}, ErrUnknownResource
	}
	if amount <= 0 || now.IsZero() {
		return StackCreditResult{}, errors.New("stack credit must be positive")
	}
	if s.Quantity > def.StackCap {
		return StackCreditResult{}, errors.New("canonical quantity exceeds catalog cap")
	}
	room := def.StackCap - s.Quantity
	fit := amount
	if fit > room {
		fit = room
	}
	overflow := amount - fit
	if overflow > 0 && !def.OverflowToMail {
		return StackCreditResult{}, ErrStackCapacity
	}
	if fit > 0 {
		s.Quantity += fit
		s.StateVersion++
		s.UpdatedAt = now.UTC()
	}
	return StackCreditResult{State: s, Fit: fit, Overflow: overflow}, nil
}

type StackAdjustmentResult struct {
	State  StackState
	Delete bool
}

// Adjust applies a signed owner delta. Positive settlement remains governed by
// PlanCredit; this method is intended for canonical debit/consumption and does
// not require an imported over-cap row to become valid before spending down.
func (s StackState) Adjust(delta int64, now time.Time) (StackAdjustmentResult, error) {
	if err := s.Validate(); err != nil {
		return StackAdjustmentResult{}, err
	}
	if delta >= 0 {
		return StackAdjustmentResult{}, errors.New("stack adjustment requires negative delta")
	}
	if now.IsZero() {
		return StackAdjustmentResult{}, errors.New("authoritative time required")
	}
	if delta == math.MinInt64 {
		return StackAdjustmentResult{}, errors.New("stack adjustment overflow")
	}
	debit := -delta
	if debit > s.Quantity {
		return StackAdjustmentResult{}, ErrInsufficientBalance
	}
	s.Quantity -= debit
	s.StateVersion++
	s.UpdatedAt = now.UTC()
	return StackAdjustmentResult{State: s, Delete: s.Quantity == 0}, nil
}
