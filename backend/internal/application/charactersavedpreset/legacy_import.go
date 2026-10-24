package charactersavedpreset

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"sort"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type LegacyRaw struct {
	SaveTeam     string
	SaveTeamName string
	SavePet      string
}

type QuarantineFinding struct {
	Code   string
	Detail string
}

func (q QuarantineFinding) Error() string {
	if q.Detail == "" {
		return q.Code
	}
	return q.Code + ": " + q.Detail
}

type HeroIdentityMapper interface {
	MapLegacyHero(context.Context, identity.PlayerID, int64) (character.HeroRef, bool, error)
}

type PetIdentityMapper interface {
	MapLegacyPet(context.Context, identity.PlayerID, int64) (character.PetRef, bool, error)
}

type LegacyIdentityMappers struct {
	Heroes HeroIdentityMapper
	Pets   PetIdentityMapper
}

type sourceLane struct {
	name   string
	heroes []int64
	pet    int64
}

func quarantine(code, detail string) ([]sourceLane, *QuarantineFinding) {
	q := &QuarantineFinding{Code: code, Detail: detail}
	return nil, q
}

func ParseLegacy(raw LegacyRaw) ([]sourceLane, *QuarantineFinding) {
	if raw.SaveTeam == "" {
		if raw.SaveTeamName != "" || raw.SavePet != "" {
			return quarantine("UNMATCHED_FIELDS", "name/pet state exists without Hero lanes")
		}
		return []sourceLane{}, nil
	}
	teamParts := strings.Split(raw.SaveTeam, ":")
	nameParts := []string{}
	if raw.SaveTeamName != "" {
		nameParts = strings.Split(raw.SaveTeamName, "|||")
	}
	petParts := []string{}
	if raw.SavePet != "" {
		petParts = strings.Split(raw.SavePet, "|")
	}
	if len(nameParts) > len(teamParts) || len(petParts) > len(teamParts) {
		return quarantine("UNMATCHED_FIELDS", "name/pet positions exceed Hero lane count")
	}
	lanes := make([]sourceLane, len(teamParts))
	for i, rawTeam := range teamParts {
		if rawTeam == "" {
			return quarantine("EMPTY_HERO_LANE", fmt.Sprintf("lane %d", i+1))
		}
		heroParts := strings.Split(rawTeam, "|")
		if len(heroParts) == 0 {
			return quarantine("EMPTY_HERO_LANE", fmt.Sprintf("lane %d", i+1))
		}
		lane := sourceLane{}
		for _, tok := range heroParts {
			if tok == "" {
				return quarantine("MALFORMED_HERO", fmt.Sprintf("lane %d has empty Hero token", i+1))
			}
			id, err := strconv.ParseInt(tok, 10, 64)
			if err != nil || id <= 0 {
				return quarantine("INVALID_HERO", fmt.Sprintf("lane %d token %q", i+1, tok))
			}
			lane.heroes = append(lane.heroes, id)
		}
		if i < len(nameParts) {
			lane.name = nameParts[i]
		}
		if strings.Contains(lane.name, "|||") {
			return quarantine("NON_PROJECTABLE_NAME", fmt.Sprintf("lane %d", i+1))
		}
		if i < len(petParts) && petParts[i] != "" && petParts[i] != "0" {
			id, err := strconv.ParseInt(petParts[i], 10, 64)
			if err != nil || id <= 0 {
				return quarantine("INVALID_PET", fmt.Sprintf("lane %d token %q", i+1, petParts[i]))
			}
			lane.pet = id
		}
		lanes[i] = lane
	}
	return lanes, nil
}

func MapLegacy(ctx context.Context, playerID identity.PlayerID, raw LegacyRaw, maps LegacyIdentityMappers) ([]character.SavedPresetLane, *QuarantineFinding, error) {
	if !playerID.Valid() || maps.Heroes == nil || maps.Pets == nil {
		return nil, nil, errors.New("saved preset: invalid legacy mapping input")
	}
	src, q := ParseLegacy(raw)
	if q != nil {
		return nil, q, nil
	}
	out := make([]character.SavedPresetLane, len(src))
	for i, lane := range src {
		mapped := character.SavedPresetLane{Name: lane.name, Heroes: make([]character.HeroRef, len(lane.heroes))}
		for j, oldID := range lane.heroes {
			ref, ok, err := maps.Heroes.MapLegacyHero(ctx, playerID, oldID)
			if err != nil {
				return nil, nil, err
			}
			if !ok || ref.Validate() != nil || ref.PlayerID != playerID {
				return nil, &QuarantineFinding{Code: "UNRESOLVED_HERO", Detail: fmt.Sprintf("lane %d source Hero %d", i+1, oldID)}, nil
			}
			mapped.Heroes[j] = ref
		}
		if lane.pet > 0 {
			ref, ok, err := maps.Pets.MapLegacyPet(ctx, playerID, lane.pet)
			if err != nil {
				return nil, nil, err
			}
			if !ok || ref.Validate() != nil || ref.PlayerID != playerID {
				return nil, &QuarantineFinding{Code: "UNRESOLVED_PET", Detail: fmt.Sprintf("lane %d source Pet %d", i+1, lane.pet)}, nil
			}
			mapped.Pet = &ref
		}
		if err := mapped.Validate(playerID); err != nil {
			return nil, &QuarantineFinding{Code: "INVALID_MAPPED_LANE", Detail: fmt.Sprintf("lane %d: %v", i+1, err)}, nil
		}
		out[i] = mapped
	}
	return out, nil, nil
}

func uniqueHeroRefs(lanes []character.SavedPresetLane) []character.HeroRef {
	seen := map[character.HeroRef]struct{}{}
	out := []character.HeroRef{}
	for _, lane := range lanes {
		for _, ref := range lane.Heroes {
			if _, ok := seen[ref]; !ok {
				seen[ref] = struct{}{}
				out = append(out, ref)
			}
		}
	}
	return out
}

func uniquePetRefs(lanes []character.SavedPresetLane) []character.PetRef {
	seen := map[character.PetRef]struct{}{}
	out := []character.PetRef{}
	for _, lane := range lanes {
		if lane.Pet != nil {
			if _, ok := seen[*lane.Pet]; !ok {
				seen[*lane.Pet] = struct{}{}
				out = append(out, *lane.Pet)
			}
		}
	}
	return out
}

type keyedHero struct {
	ref character.HeroRef
	key lockkey.Key
}
type keyedPet struct {
	ref character.PetRef
	key lockkey.Key
}

// ImportLegacyTx is the CA5 domain anti-corruption adapter used by the quiesced
// Pass425 migration runner. It never assumes source IDs equal target IDs and it
// refuses to overwrite a different non-empty target aggregate.
func ImportLegacyTx(ctx context.Context, t tx.Tx, store Store, refs ReferenceOwners, maps LegacyIdentityMappers, playerID identity.PlayerID, raw LegacyRaw, now time.Time) (*QuarantineFinding, error) {
	if t == nil || store == nil || refs.Heroes == nil || refs.Pets == nil || !playerID.Valid() || now.IsZero() {
		return nil, errors.New("saved preset: invalid import input")
	}
	lanes, q, err := MapLegacy(ctx, playerID, raw, maps)
	if err != nil || q != nil {
		return q, err
	}
	if _, err := store.EnsureSavedPresetRootTx(ctx, t, playerID, now.UTC()); err != nil {
		return nil, err
	}
	heroes := uniqueHeroRefs(lanes)
	pets := uniquePetRefs(lanes)
	hks := make([]keyedHero, len(heroes))
	for i, ref := range heroes {
		k, err := refs.Heroes.HeroReferenceLockKey(ref)
		if err != nil {
			return nil, err
		}
		hks[i] = keyedHero{ref: ref, key: k}
	}
	pks := make([]keyedPet, len(pets))
	for i, ref := range pets {
		k, err := refs.Pets.PetReferenceLockKey(ref)
		if err != nil {
			return nil, err
		}
		pks[i] = keyedPet{ref: ref, key: k}
	}
	sort.Slice(hks, func(i, j int) bool { return lockkey.Compare(hks[i].key, hks[j].key) < 0 })
	sort.Slice(pks, func(i, j int) bool { return lockkey.Compare(pks[i].key, pks[j].key) < 0 })
	for _, x := range hks {
		if err := refs.Heroes.LockHeroReferenceKeyTx(ctx, t, x.key, x.ref); err != nil {
			return nil, err
		}
	}
	for _, x := range pks {
		if err := refs.Pets.LockPetReferenceKeyTx(ctx, t, x.key, x.ref); err != nil {
			return nil, err
		}
	}
	root, err := store.LockSavedPresetRootTx(ctx, t, playerID)
	if err != nil {
		return nil, err
	}
	current, err := store.ReadSavedPresetAggregateTx(ctx, t, playerID)
	if err != nil {
		return nil, err
	}
	if len(current.Lanes) != 0 {
		if reflect.DeepEqual(current.Lanes, lanes) {
			return nil, nil
		}
		return nil, ErrImportConflict
	}
	if len(lanes) == 0 {
		return nil, nil
	}
	desired := character.SavedPresetAggregate{Root: root, Lanes: lanes}
	desired.Root.StateVersion = root.StateVersion + 1
	desired.Root.UpdatedAt = now.UTC()
	if err := store.ReplaceSavedPresetAggregateTx(ctx, t, desired, root.StateVersion); err != nil {
		return nil, err
	}
	return nil, nil
}
