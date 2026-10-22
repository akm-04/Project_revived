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
	// SnapshotSchema 2 adds the BattleContext (I8-2C). Schema 1 snapshots stored
	// before it stay valid, carry no context and keep their bytes.
	SnapshotSchema       = 2
	LegacySnapshotSchema = 1
	TrustProfileID       = "SERVER_REPORT_AUTHORITATIVE_V1"
	TrustProfileVersion  = 1
	EntropyPolicyVersion = "HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1"
	AdapterPolicyVersion = "SNAPSHOT_ONLY_ADAPTERS_V1"
	CollectionPolicy     = "C5A_COMBAT_COLLECTION_ATTR_OWNER_SCOPED_V1"
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
)

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
	Transform json.RawMessage `json:"transform,omitempty"`
}

// BattleContext names the registered mode transform the resolver applies to the
// populated fight and carries its battle-wide parameter object. A new mode
// registers a transform module; it never edits the resolver.
type BattleContext struct {
	Transform  string          `json:"transform"`
	Parameters json.RawMessage `json:"parameters,omitempty"`
}

var transformID = regexp.MustCompile(`^[A-Z][A-Z0-9_]*_V[1-9][0-9]*$`)

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

func (a Actor) validate(kind ActorKind, players map[int64]bool) error {
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
	switch a.Origin {
	case Template:
		if a.Player != 0 || a.OwnerStateVersion != 0 || len(a.BattleTotals) != 0 || (params.PlayerID != nil && params.PlayerID.String() != "0") {
			return ErrInvalid
		}
	case OwnedSelf, OwnedForeign:
		if a.Player <= 0 || !players[a.Player] || a.OwnerStateVersion <= 0 || len(a.BattleTotals) == 0 || params.PlayerID == nil || params.PlayerID.String() != fmt.Sprint(a.Player) {
			return ErrInvalid
		}
	default:
		return ErrInvalid
	}
	return nil
}

func (s Snapshot) Validate() error {
	if (s.Schema != SnapshotSchema && s.Schema != LegacySnapshotSchema) || s.Contract != ContractID || len(s.ContentRevision) != 64 || len(s.CorpusID) != 64 || len(s.SourceArchiveSHA256) != 64 || s.TrustProfile != TrustProfileID || s.EntropyPolicy != EntropyPolicyVersion || s.AdapterPolicy != AdapterPolicyVersion || s.CollectionPolicy != CollectionPolicy || s.DecidedAt.IsZero() || s.DecidedAt.Location() != time.UTC {
		return ErrInvalid
	}
	b := s.Battle
	if b.CampaignType <= 0 || b.BattleID < 0 || len(b.TeamA) == 0 || len(b.WavesB) == 0 || !s.contextValid() {
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
			if err := a.validate(kind, players); err != nil {
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
		if a.Origin == Template {
			continue
		}
		if err := profile.CheckOwned(a.Kind, a.Params); err != nil {
			return fmt.Errorf("%w: %v", ErrInvalid, err)
		}
	}
	return nil
}

// contextValid admits actor transform parameters only beside a context, and no
// context in schema 1.
func (s Snapshot) contextValid() bool {
	context := s.Battle.Context
	if context != nil && (s.Schema == LegacySnapshotSchema || !transformID.MatchString(context.Transform) || (len(context.Parameters) != 0 && !canonicalObject(context.Parameters))) {
		return false
	}
	for _, a := range s.actors() {
		if len(a.Transform) != 0 && context == nil {
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
