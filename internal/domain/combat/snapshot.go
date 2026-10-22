// Package combat owns the immutable combat input snapshot, the durable attempt
// envelope (Pass418), the entropy stream and the resolution record. It never
// reads mode, owner or wall-clock state.
package combat

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strconv"
	"time"
)

const (
	ContractID = "C5A_COMBAT_INPUT_ATTEMPT_RESULT_FOUNDATION_V1"
	// SnapshotSchema 3 adds the attempt's trust profile and BORROWED/TRIAL
	// provenance (I8-4); schema 2 added the BattleContext (I8-2C). Older
	// snapshots stay valid under their own rules and keep their bytes.
	SnapshotSchema        = 3
	ContextSnapshotSchema = 2
	LegacySnapshotSchema  = 1
	TrustProfileID        = "SERVER_REPORT_AUTHORITATIVE_V1"
	TrustProfileVersion   = 1
	EntropyPolicyVersion  = "HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1"
	AdapterPolicyVersion  = "SNAPSHOT_ONLY_ADAPTERS_V1"
	CollectionPolicy      = "C5A_COMBAT_COLLECTION_ATTR_OWNER_SCOPED_V1"
	// AttemptLockRank follows the mode roots 601..608 and precedes I5 Grant 610+.
	AttemptLockRank uint16 = 609
	// ExclusiveBookFirst..Last are NormalHero.getZhugeBookSkillNum's item IDs.
	ExclusiveBookFirst int64 = 50000001
	ExclusiveBookLast  int64 = 50000025
)

var (
	ErrInvalid             = errors.New("combat: invalid input")
	ErrClassUnavailable    = errors.New("combat: CLASS_UNAVAILABLE_IN_PINNED_PROFILE")
	ErrProviderUnavailable = errors.New("combat: input provider unavailable")
	ErrContentMismatch     = errors.New("combat: content revision does not match the rules corpus")
	ErrKeyUnavailable      = errors.New("combat: entropy key version unavailable")
	ErrStartConflict       = errors.New("combat: different START for an unresolved attempt")
	ErrNotReady            = errors.New("combat: attempt has no resolution")
	ErrIntegrity           = errors.New("combat: stored combat record failed integrity validation")
	ErrStale               = errors.New("combat: attempt state version or generation changed")
	// ErrLoanRefused is a lending capability refusing a BORROWED actor (H-40).
	ErrLoanRefused = errors.New("combat: loan refused by the lending capability")
	// ErrResolverRetryable covers crash, timeout and resource kill: identical inputs may succeed.
	ErrResolverRetryable = errors.New("combat: resolver failed retryably")
	// ErrResolverPermanent covers deterministic script or validation failure.
	ErrResolverPermanent = errors.New("combat: resolver failed permanently")
)

type Origin string

const (
	OwnedSelf    Origin = "OWNED_SELF"
	OwnedForeign Origin = "OWNED_FOREIGN"
	Template     Origin = "TEMPLATE"
	// Borrowed is another player's owned actor fighting for the borrower; it
	// keeps the owned shape and names the lender (I8-6A freezes it).
	Borrowed Origin = "BORROWED"
	// Trial is a template-derived actor that never persists (AUDIT-PROFILE-04).
	Trial Origin = "TRIAL"
)

// Provenance names the capability and its version that granted a BORROWED or
// TRIAL actor, and the source reference (loan or trial entry) it came from.
type Provenance struct {
	Capability string `json:"capability"`
	Reference  string `json:"reference"`
}

func (p *Provenance) Valid() bool {
	return p != nil && versionedID.MatchString(p.Capability) && p.Reference != "" && len(p.Reference) <= 256
}

type ActorKind string

const (
	HeroActor ActorKind = "HERO"
	PetActor  ActorKind = "PET"
)

// Actor carries source-shaped populate params; owned actors also carry the
// owner state version and the canonical 3B battle-total facet (differential oracle).
type Actor struct {
	Origin            Origin          `json:"origin"`
	Kind              ActorKind       `json:"kind"`
	Player            int64           `json:"player_id"`
	Identity          int64           `json:"identity"`
	TableID           int64           `json:"table_id"`
	FighterClass      string          `json:"fighter_class"`
	OwnerStateVersion int64           `json:"owner_state_version"`
	Params            json.RawMessage `json:"params"`
	BattleTotals      json.RawMessage `json:"battle_totals,omitempty"`
	// Transform is this actor's parameter object for the battle's registered transform.
	Transform  json.RawMessage `json:"transform,omitempty"`
	Provenance *Provenance     `json:"provenance,omitempty"`
}

// BattleContext names the registered mode transform the resolver applies to the
// populated fight and carries its battle-wide parameter object. A new mode
// registers a transform module; it never edits the resolver.
type BattleContext struct {
	Transform  string          `json:"transform"`
	Parameters json.RawMessage `json:"parameters,omitempty"`
}

var versionedID = regexp.MustCompile(`^[A-Z][A-Z0-9_]*_V[1-9][0-9]*$`)

func canonicalObject(raw json.RawMessage) bool {
	canonical, err := CanonicalJSON(raw)
	return err == nil && bytes.Equal(canonical, raw) && canonical[0] == '{'
}

// PlayerContext is the per-player state the server branch reads outside params:
// collection (white album) attr in hundredths and the exact quantities of the
// exclusive book items lib.player.backpack is asked about.
type PlayerContext struct {
	Player               int64            `json:"player_id"`
	StateVersions        map[string]int64 `json:"state_versions"`
	CollectionHundredths map[string]int64 `json:"collection_hundredths"`
	ExclusiveBooks       map[string]int64 `json:"exclusive_books"`
}

type Battle struct {
	CampaignType int64     `json:"campaign_type"`
	BattleID     int64     `json:"battle_id"`
	TeamA        []Actor   `json:"team_a"`
	PetsA        []Actor   `json:"pets_a"`
	WavesB       [][]Actor `json:"waves_b"`
	PetsB        []Actor   `json:"pets_b"`
	// Context is absent for a battle without a mode transform and in schema 1.
	Context *BattleContext `json:"context,omitempty"`
	// Formation is the stock slot-ordered formation a client-run START froze
	// (0 = empty slot); its summary validator compares the RESULT against it.
	Formation []int64 `json:"formation,omitempty"`
}

type Snapshot struct {
	Schema              int             `json:"schema"`
	Contract            string          `json:"contract"`
	ContentRevision     string          `json:"content_revision"`
	CorpusID            string          `json:"corpus_id"`
	SourceArchiveSHA256 string          `json:"source_archive_sha256"`
	TrustProfile        string          `json:"trust_profile"`
	EntropyPolicy       string          `json:"entropy_policy"`
	AdapterPolicy       string          `json:"adapter_policy"`
	CollectionPolicy    string          `json:"collection_policy"`
	DecidedAt           time.Time       `json:"decided_at"`
	Battle              Battle          `json:"battle"`
	Players             []PlayerContext `json:"players"`
	// ProducerProfile pins the battle producer registry (schema 2 only).
	ProducerProfile string `json:"producer_profile,omitempty"`
	// Challenge replaces the battle of a client-derived minigame START (D20(a)).
	Challenge *Challenge `json:"challenge,omitempty"`
}

// OSTime is the frozen value the VM's os.time returns.
func (s Snapshot) OSTime() int64 { return s.DecidedAt.Unix() }

// CanonicalJSON re-encodes v with sorted object keys and exact number literals.
func CanonicalJSON(v any) (json.RawMessage, error) {
	raw, err := json.Marshal(v)
	if err != nil {
		return nil, err
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	var generic any
	if err = decoder.Decode(&generic); err != nil {
		return nil, err
	}
	return json.Marshal(generic)
}

func (s Snapshot) actors() []Actor {
	all := append(append([]Actor{}, s.Battle.TeamA...), s.Battle.PetsA...)
	for _, wave := range s.Battle.WavesB {
		all = append(all, wave...)
	}
	return append(all, s.Battle.PetsB...)
}

func (a Actor) validate(kind ActorKind, players map[int64]bool, schema int) error {
	if a.Kind != kind || a.TableID <= 0 || a.Identity <= 0 || a.FighterClass == "" || len(a.Params) == 0 {
		return ErrInvalid
	}
	if !canonicalObject(a.Params) || (len(a.Transform) != 0 && !canonicalObject(a.Transform)) {
		return ErrInvalid
	}
	var params struct {
		PlayerID *json.Number `json:"player_id"`
		TableID  json.Number  `json:"table_id"`
	}
	if err := json.Unmarshal(a.Params, &params); err != nil || params.TableID.String() != fmt.Sprint(a.TableID) {
		return ErrInvalid
	}
	provenanced := a.Origin == Borrowed || a.Origin == Trial
	if provenanced != (a.Provenance != nil) || provenanced && (schema < SnapshotSchema || !a.Provenance.Valid()) {
		return ErrInvalid
	}
	switch a.Origin {
	case Template, Trial:
		if a.Player != 0 || a.OwnerStateVersion != 0 || len(a.BattleTotals) != 0 || (params.PlayerID != nil && params.PlayerID.String() != "0") {
			return ErrInvalid
		}
	case OwnedSelf, OwnedForeign, Borrowed:
		if a.Player <= 0 || !players[a.Player] || a.OwnerStateVersion <= 0 || len(a.BattleTotals) == 0 || params.PlayerID == nil || params.PlayerID.String() != fmt.Sprint(a.Player) {
			return ErrInvalid
		}
	default:
		return ErrInvalid
	}
	return nil
}

func (s Snapshot) Validate() error {
	profile := s.TrustProfile == TrustProfileID || s.Schema == SnapshotSchema && registeredProfileID(s.TrustProfile)
	if s.Schema < LegacySnapshotSchema || s.Schema > SnapshotSchema || s.Contract != ContractID || len(s.ContentRevision) != 64 || len(s.CorpusID) != 64 || len(s.SourceArchiveSHA256) != 64 || !profile || s.EntropyPolicy != EntropyPolicyVersion || s.AdapterPolicy != AdapterPolicyVersion || s.CollectionPolicy != CollectionPolicy || s.DecidedAt.IsZero() || s.DecidedAt.Location() != time.UTC {
		return ErrInvalid
	}
	if s.Challenge != nil {
		return s.challengeValid()
	}
	b := s.Battle
	if b.CampaignType <= 0 || b.BattleID < 0 || len(b.TeamA) == 0 || len(b.WavesB) == 0 && !s.enemyUnnamed() || !s.contextValid() || !s.formationValid() || !s.borrowedValid() {
		return ErrInvalid
	}
	players := map[int64]bool{}
	for i, p := range s.Players {
		if p.Player <= 0 || players[p.Player] || (i > 0 && s.Players[i-1].Player >= p.Player) || len(p.StateVersions) == 0 || p.CollectionHundredths == nil || p.ExclusiveBooks == nil {
			return ErrInvalid
		}
		for k, v := range p.StateVersions {
			if k == "" || v <= 0 {
				return ErrInvalid
			}
		}
		for k, quantity := range p.ExclusiveBooks {
			id, err := strconv.ParseInt(k, 10, 64)
			if err != nil || strconv.FormatInt(id, 10) != k || id < ExclusiveBookFirst || id > ExclusiveBookLast || quantity <= 0 {
				return ErrInvalid
			}
		}
		players[p.Player] = true
	}
	check := func(actors []Actor, kind ActorKind) error {
		for _, a := range actors {
			if err := a.validate(kind, players, s.Schema); err != nil {
				return err
			}
		}
		return nil
	}
	for _, wave := range b.WavesB {
		if len(wave) == 0 {
			return ErrInvalid
		}
		if err := check(wave, HeroActor); err != nil {
			return err
		}
	}
	for _, err := range []error{check(b.TeamA, HeroActor), check(b.PetsA, PetActor), check(b.PetsB, PetActor)} {
		if err != nil {
			return err
		}
	}
	used := map[int64]bool{}
	for _, a := range s.actors() {
		used[a.Player] = true
	}
	for player := range players {
		if !used[player] {
			return ErrInvalid
		}
	}
	return s.producersValid()
}

// producersValid audits owned actors against the pinned producer profile;
// schema 1 snapshots predate the registry and carry none.
func (s Snapshot) producersValid() error {
	if s.Schema == LegacySnapshotSchema {
		if s.ProducerProfile != "" {
			return ErrInvalid
		}
		return nil
	}
	profile, ok := LookupProducerProfile(s.ProducerProfile)
	if !ok {
		return ErrInvalid
	}
	for _, a := range s.actors() {
		if a.Origin == Template || a.Origin == Trial {
			continue
		}
		if err := profile.CheckOwned(a.Kind, a.Params); err != nil {
			return fmt.Errorf("%w: %v", ErrInvalid, err)
		}
	}
	return nil
}

// challengeValid admits a challenge only on a schema 3 client-derived
// snapshot with no battle, players or producer profile.
func (s Snapshot) challengeValid() error {
	b := s.Battle
	battleless := b.CampaignType == 0 && b.BattleID == 0 && b.Context == nil && len(b.TeamA)+len(b.PetsA)+len(b.WavesB)+len(b.PetsB)+len(b.Formation) == 0
	if s.Schema != SnapshotSchema || s.TrustProfile != ServerEntropyClientDerived.ID || !battleless || len(s.Players) != 0 || s.ProducerProfile != "" || !s.Challenge.valid() {
		return ErrInvalid
	}
	return nil
}

// borrowedValid admits BORROWED actors on the attacking side only, at most one
// Hero and one Pet: the stock START carries one rent_formation Hero and one
// rent_pet_id (D22c).
func (s Snapshot) borrowedValid() bool {
	b := s.Battle
	sideB := borrowedCount(b.PetsB)
	for _, wave := range b.WavesB {
		sideB += borrowedCount(wave)
	}
	return sideB == 0 && borrowedCount(b.TeamA) <= 1 && borrowedCount(b.PetsA) <= 1
}

func borrowedCount(actors []Actor) int {
	count := 0
	for _, a := range actors {
		if a.Origin == Borrowed {
			count++
		}
	}
	return count
}

// enemyUnnamed admits a client-summary snapshot without enemy waves when the
// family's START names no enemy (Conquer picks its team client-side, D21a).
func (s Snapshot) enemyUnnamed() bool {
	return s.Schema == SnapshotSchema && s.TrustProfile == ClientSummaryAttested.ID && len(s.Battle.Formation) > 0
}

// contextValid admits actor transform parameters only beside a context, and no
// context in schema 1.
func (s Snapshot) contextValid() bool {
	context := s.Battle.Context
	if context != nil && (s.Schema == LegacySnapshotSchema || !versionedID.MatchString(context.Transform) || (len(context.Parameters) != 0 && !canonicalObject(context.Parameters))) {
		return false
	}
	for _, a := range s.actors() {
		if len(a.Transform) != 0 && context == nil {
			return false
		}
	}
	return true
}

// formationValid allows a formation only on a schema 3 client-run snapshot,
// where its occupied slots name the TeamA heroes in order.
func (s Snapshot) formationValid() bool {
	formation := s.Battle.Formation
	if len(formation) == 0 {
		return true
	}
	if s.Schema != SnapshotSchema || s.TrustProfile == TrustProfileID {
		return false
	}
	occupied := []int64{}
	for _, identity := range formation {
		if identity < 0 {
			return false
		}
		if identity > 0 {
			occupied = append(occupied, identity)
		}
	}
	if len(occupied) != len(s.Battle.TeamA) {
		return false
	}
	for i, a := range s.Battle.TeamA {
		if a.Identity != occupied[i] {
			return false
		}
	}
	return true
}

// Canonical returns the immutable encoding whose SHA-256 addresses the snapshot.
func (s Snapshot) Canonical() ([]byte, string, error) {
	if err := s.Validate(); err != nil {
		return nil, "", err
	}
	raw, err := json.Marshal(s)
	if err != nil {
		return nil, "", err
	}
	sum := sha256.Sum256(raw)
	return raw, hex.EncodeToString(sum[:]), nil
}

// DecodeSnapshot verifies stored bytes against their address before use.
func DecodeSnapshot(raw []byte, hash string) (Snapshot, error) {
	var s Snapshot
	if err := json.Unmarshal(raw, &s); err != nil {
		return s, ErrIntegrity
	}
	again, got, err := s.Canonical()
	if err != nil || got != hash || !bytes.Equal(again, raw) {
		return s, ErrIntegrity
	}
	return s, nil
}
