package charactersavedpreset

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
)

var (
	ErrInvalidCommand        = errors.New("saved preset: invalid command")
	ErrStaleLegacyDelete     = errors.New("saved preset: stale legacy delete")
	ErrAmbiguousLegacyDelete = errors.New("saved preset: ambiguous legacy delete")
)

var fixedProjectionTime = time.Unix(1, 0).UTC()

// Command carries the stock MID1793 gameplay fields after the stockruntime edge
// has preserved whether pet_str was present. Missing and present-empty pet_str
// are different wire shapes and must never be collapsed.
type Command struct {
	TeamString     string
	TeamNameString string
	PetPresent     bool
	PetString      string
}

func (c Command) FullForm() bool { return c.PetPresent }

// ParseFullCommand converts the current three-string MID1793 form into one
// actor-scoped canonical desired aggregate. The live command parser is strict:
// unlike the historical importer, it never pads positional vectors or
// normalizes non-canonical integer spellings.
func ParseFullCommand(playerID identity.PlayerID, cmd Command) ([]character.SavedPresetLane, error) {
	if !playerID.Valid() || !cmd.PetPresent {
		return nil, ErrInvalidCommand
	}
	if cmd.TeamString == "" {
		if cmd.TeamNameString != "" || cmd.PetString != "" {
			return nil, ErrInvalidCommand
		}
		return []character.SavedPresetLane{}, nil
	}

	teamParts := strings.Split(cmd.TeamString, ":")
	nameParts := strings.Split(cmd.TeamNameString, "|||")
	petParts := strings.Split(cmd.PetString, "|")
	if len(teamParts) != len(nameParts) || len(teamParts) != len(petParts) {
		return nil, ErrInvalidCommand
	}

	lanes := make([]character.SavedPresetLane, len(teamParts))
	for i := range teamParts {
		if teamParts[i] == "" {
			return nil, ErrInvalidCommand
		}
		heroParts := strings.Split(teamParts[i], "|")
		if len(heroParts) == 0 {
			return nil, ErrInvalidCommand
		}
		lane := character.SavedPresetLane{Name: nameParts[i], Heroes: make([]character.HeroRef, len(heroParts))}
		for j, token := range heroParts {
			id, err := parseCanonicalPositiveInt64(token)
			if err != nil {
				return nil, fmt.Errorf("%w: Hero lane %d token %d", ErrInvalidCommand, i+1, j+1)
			}
			lane.Heroes[j] = character.HeroRef{PlayerID: playerID, PartnerID: id}
		}
		if petParts[i] != "0" {
			id, err := parseCanonicalPositiveInt64(petParts[i])
			if err != nil {
				return nil, fmt.Errorf("%w: Pet lane %d", ErrInvalidCommand, i+1)
			}
			ref := character.PetRef{PlayerID: playerID, PetID: id}
			lane.Pet = &ref
		}
		if err := lane.Validate(playerID); err != nil {
			return nil, fmt.Errorf("%w: lane %d", ErrInvalidCommand, i+1)
		}
		lanes[i] = lane
	}

	// Exact projection is part of the live-command contract. It rejects numeric
	// aliases such as +1/01 and any non-projectable shape without inventing a
	// second normalization vocabulary.
	projected, err := projectLanes(playerID, lanes)
	if err != nil || projected.SaveTeam != cmd.TeamString || projected.SaveTeamName != cmd.TeamNameString || projected.SavePet != cmd.PetString {
		return nil, ErrInvalidCommand
	}
	return lanes, nil
}

// ValidateLegacyCommandShape validates only the Hero/name half of the retained
// pet-less delete form. The actual canonical result can be determined only from
// the locked current aggregate and is therefore resolved by ResolveLegacyDelete.
func ValidateLegacyCommandShape(playerID identity.PlayerID, cmd Command) error {
	if !playerID.Valid() || cmd.PetPresent {
		return ErrInvalidCommand
	}
	if cmd.TeamString == "" {
		if cmd.TeamNameString != "" {
			return ErrInvalidCommand
		}
		return nil
	}
	teamParts := strings.Split(cmd.TeamString, ":")
	nameParts := strings.Split(cmd.TeamNameString, "|||")
	if len(teamParts) != len(nameParts) {
		return ErrInvalidCommand
	}
	lanes := make([]character.SavedPresetLane, len(teamParts))
	for i := range teamParts {
		if teamParts[i] == "" {
			return ErrInvalidCommand
		}
		heroParts := strings.Split(teamParts[i], "|")
		lane := character.SavedPresetLane{Name: nameParts[i], Heroes: make([]character.HeroRef, len(heroParts))}
		for j, token := range heroParts {
			id, err := parseCanonicalPositiveInt64(token)
			if err != nil {
				return ErrInvalidCommand
			}
			lane.Heroes[j] = character.HeroRef{PlayerID: playerID, PartnerID: id}
		}
		if err := lane.Validate(playerID); err != nil {
			return ErrInvalidCommand
		}
		lanes[i] = lane
	}
	projected, err := projectLanes(playerID, lanes)
	if err != nil || projected.SaveTeam != cmd.TeamString || projected.SaveTeamName != cmd.TeamNameString {
		return ErrInvalidCommand
	}
	return nil
}

// ResolveLegacyDelete interprets the retained pet-less delete request against
// the locked current aggregate. It never guesses an index: multiple matching
// indices are accepted only when they all yield the same complete canonical
// aggregate, including Pet alignment.
func ResolveLegacyDelete(current character.SavedPresetAggregate, cmd Command) ([]character.SavedPresetLane, error) {
	if err := current.Validate(); err != nil {
		return nil, err
	}
	if err := ValidateLegacyCommandShape(current.Root.PlayerID, cmd); err != nil {
		return nil, err
	}
	wire, err := ProjectWire(current)
	if err != nil {
		return nil, err
	}
	if wire.SaveTeam == cmd.TeamString && wire.SaveTeamName == cmd.TeamNameString {
		return cloneSavedPresetLanes(current.Lanes), nil
	}

	var resolved []character.SavedPresetLane
	matched := false
	for i := range current.Lanes {
		candidate := removeSavedPresetLane(current.Lanes, i)
		projected, err := projectLanes(current.Root.PlayerID, candidate)
		if err != nil {
			return nil, err
		}
		if projected.SaveTeam != cmd.TeamString || projected.SaveTeamName != cmd.TeamNameString {
			continue
		}
		if !matched {
			resolved = candidate
			matched = true
			continue
		}
		if !SavedPresetLanesEqual(resolved, candidate) {
			return nil, ErrAmbiguousLegacyDelete
		}
	}
	if !matched {
		return nil, ErrStaleLegacyDelete
	}
	return resolved, nil
}

// SavedPresetLanesEqual is the semantic equality used by CA5-3 convergence.
// Root revision/timestamps are intentionally outside this comparison.
func SavedPresetLanesEqual(a, b []character.SavedPresetLane) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i].Name != b[i].Name || len(a[i].Heroes) != len(b[i].Heroes) {
			return false
		}
		for j := range a[i].Heroes {
			if a[i].Heroes[j] != b[i].Heroes[j] {
				return false
			}
		}
		switch {
		case a[i].Pet == nil && b[i].Pet == nil:
		case a[i].Pet == nil || b[i].Pet == nil:
			return false
		case *a[i].Pet != *b[i].Pet:
			return false
		}
	}
	return true
}

func parseCanonicalPositiveInt64(token string) (int64, error) {
	if token == "" || token[0] < '1' || token[0] > '9' {
		return 0, ErrInvalidCommand
	}
	for i := 1; i < len(token); i++ {
		if token[i] < '0' || token[i] > '9' {
			return 0, ErrInvalidCommand
		}
	}
	id, err := strconv.ParseInt(token, 10, 64)
	if err != nil || id <= 0 || strconv.FormatInt(id, 10) != token {
		return 0, ErrInvalidCommand
	}
	return id, nil
}

func projectLanes(playerID identity.PlayerID, lanes []character.SavedPresetLane) (WireProjection, error) {
	nowRoot := character.SavedPresetRoot{PlayerID: playerID, StateVersion: 1}
	// ProjectWire requires a valid durable root even though projection depends
	// only on lanes. Use nonzero metadata solely for pure validation/projection.
	nowRoot.CreatedAt = fixedProjectionTime
	nowRoot.UpdatedAt = fixedProjectionTime
	return ProjectWire(character.SavedPresetAggregate{Root: nowRoot, Lanes: lanes})
}

func removeSavedPresetLane(lanes []character.SavedPresetLane, index int) []character.SavedPresetLane {
	out := make([]character.SavedPresetLane, 0, len(lanes)-1)
	out = append(out, cloneSavedPresetLanes(lanes[:index])...)
	out = append(out, cloneSavedPresetLanes(lanes[index+1:])...)
	return out
}

func cloneSavedPresetLanes(lanes []character.SavedPresetLane) []character.SavedPresetLane {
	out := make([]character.SavedPresetLane, len(lanes))
	for i := range lanes {
		out[i].Name = lanes[i].Name
		out[i].Heroes = append([]character.HeroRef(nil), lanes[i].Heroes...)
		if lanes[i].Pet != nil {
			ref := *lanes[i].Pet
			out[i].Pet = &ref
		}
	}
	return out
}
