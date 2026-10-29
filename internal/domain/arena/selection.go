package arena

import (
	"cmp"
	"slices"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const (
	SelectionTeamCount = 3
	SelectionPetTurn   = 6
	SelectionDoneTurn  = 8
)

type SelectionHero struct {
	Identifier      int64 `json:"identifier"`
	TableIdentifier int64 `json:"table_identifier"`
}

type SelectionRoster struct {
	Heroes []SelectionHero
	Pets   []int64
}

// SelectedFormation uses owned instance identities, unlike Arena's table-ID defense Lineup.
type SelectedFormation struct {
	Heroes []int64 `json:"heroes"`
	Pet    int64   `json:"pet"`
}

type SelectionRoom struct {
	RequiredTeams int                                      `json:"required_teams,omitempty"`
	Players       [2]identity.PlayerID                     `json:"players"`
	Teams         [2][SelectionTeamCount]SelectedFormation `json:"teams"`
	Team          int                                      `json:"team"`
	Turn          int                                      `json:"turn"`
	Deadline      time.Time                                `json:"deadline"`
}

type SelectionCommand struct {
	Player    identity.PlayerID
	Turn      int
	Formation SelectedFormation
}

func NewSelectionRoom(first, second identity.PlayerID, at time.Time) (SelectionRoom, error) {
	room := SelectionRoom{Players: [2]identity.PlayerID{first, second}, Team: 1, Deadline: at.Add(SelectionTurnLifetime)}
	if at.IsZero() || room.Validate() != nil {
		return SelectionRoom{}, ErrInvalid
	}
	return room, nil
}

func (room SelectionRoom) Validate() error {
	if !room.Players[0].Valid() || !room.Players[1].Valid() || room.Players[0] == room.Players[1] || room.Team < 1 || room.Team > room.TeamCount() || room.Turn < 0 || room.Turn > SelectionDoneTurn || room.Deadline.IsZero() {
		return ErrInvalid
	}
	if (room.RequiredTeams != 0 && room.RequiredTeams != 1 && room.RequiredTeams != SelectionTeamCount) || (room.Turn == SelectionDoneTurn && room.Team != room.TeamCount()) {
		return ErrInvalid
	}
	return nil
}

func (room SelectionRoom) Complete() bool {
	return room.Team == room.TeamCount() && room.Turn == SelectionDoneTurn
}

func (room SelectionRoom) Select(command SelectionCommand, roster SelectionRoster, at time.Time) (SelectionRoom, error) {
	if room.Validate() != nil || at.IsZero() {
		return SelectionRoom{}, ErrInvalid
	}
	if room.Complete() || command.Turn != room.Turn || command.Player != room.Players[room.Turn%2] || !at.Before(room.Deadline) {
		return SelectionRoom{}, ErrRefused
	}
	side := room.Turn % 2
	available, err := room.available(roster, side)
	if err != nil {
		return SelectionRoom{}, err
	}
	current := room.Teams[side][room.Team-1]
	if room.Turn < SelectionPetTurn {
		if err := validateHeroChoice(current, command.Formation, available, selectionHeroCount(room.Turn)); err != nil {
			return SelectionRoom{}, err
		}
		return room.advance(command.Formation, at), nil
	}
	if !slices.Equal(command.Formation.Heroes, current.Heroes) || validateOwnedSelection(current.Heroes, available.Heroes) != nil || !validSelectedPet(command.Formation.Pet, available.Pets) {
		return SelectionRoom{}, ErrRefused
	}
	return room.advance(command.Formation, at), nil
}

func validateHeroChoice(current, chosen SelectedFormation, available SelectionRoster, required int) error {
	if chosen.Pet != 0 || len(chosen.Heroes) != required || len(current.Heroes) > len(chosen.Heroes) || !slices.Equal(current.Heroes, chosen.Heroes[:len(current.Heroes)]) {
		return ErrRefused
	}
	return validateOwnedSelection(chosen.Heroes, available.Heroes)
}

func validateOwnedSelection(chosen []int64, available []SelectionHero) error {
	if len(chosen) > TeamSize {
		return ErrRefused
	}
	owned := map[int64]int64{}
	for _, hero := range available {
		owned[hero.Identifier] = hero.TableIdentifier
	}
	seen := map[int64]bool{}
	for _, identifier := range chosen {
		tableIdentifier, found := owned[identifier]
		if !found || seen[tableIdentifier] {
			return ErrRefused
		}
		seen[tableIdentifier] = true
	}
	return nil
}

func validSelectedPet(identifier int64, available []int64) bool {
	if len(available) == 0 {
		return identifier == 0
	}
	return slices.Contains(available, identifier)
}

func selectionHeroCount(turn int) int {
	counts := [SelectionPetTurn]int{1, 2, 3, 4, TeamSize, TeamSize}
	return counts[turn]
}

func (room SelectionRoom) available(roster SelectionRoster, side int) (SelectionRoster, error) {
	usedHeroes := map[int64]bool{}
	usedPets := map[int64]bool{}
	for _, previous := range room.Teams[side][:room.Team-1] {
		for _, identifier := range previous.Heroes {
			usedHeroes[identifier] = true
		}
		usedPets[previous.Pet] = true
	}
	available := SelectionRoster{}
	seenHeroes := map[int64]bool{}
	for _, hero := range roster.Heroes {
		if hero.Identifier <= 0 || hero.TableIdentifier <= 0 || seenHeroes[hero.Identifier] {
			return SelectionRoster{}, ErrInvalid
		}
		seenHeroes[hero.Identifier] = true
		if !usedHeroes[hero.Identifier] {
			available.Heroes = append(available.Heroes, hero)
		}
	}
	seenPets := map[int64]bool{}
	for _, pet := range roster.Pets {
		if pet <= 0 || seenPets[pet] {
			return SelectionRoster{}, ErrInvalid
		}
		seenPets[pet] = true
		if !usedPets[pet] {
			available.Pets = append(available.Pets, pet)
		}
	}
	return available, nil
}

// Expire advances only a due canonical turn; no public request can choose the fallback roster.
func (room SelectionRoom) Expire(roster SelectionRoster, at time.Time) (SelectionRoom, error) {
	if room.Validate() != nil || at.IsZero() {
		return SelectionRoom{}, ErrInvalid
	}
	if room.Complete() || at.Before(room.Deadline) {
		return room, nil
	}
	side := room.Turn % 2
	available, err := room.available(roster, side)
	if err != nil {
		return SelectionRoom{}, err
	}
	chosen := SelectedFormation{Heroes: slices.Clone(room.Teams[side][room.Team-1].Heroes)}
	slices.SortFunc(available.Heroes, func(left, right SelectionHero) int {
		return cmp.Compare(left.Identifier, right.Identifier)
	})
	legal := map[int64]int64{}
	for _, hero := range available.Heroes {
		legal[hero.Identifier] = hero.TableIdentifier
	}
	chosen.Heroes = slices.DeleteFunc(chosen.Heroes, func(identifier int64) bool { return legal[identifier] == 0 })
	seen := map[int64]bool{}
	for _, identifier := range chosen.Heroes {
		seen[legal[identifier]] = true
	}
	required := TeamSize
	if room.Turn < SelectionPetTurn {
		required = selectionHeroCount(room.Turn)
	}
	for _, hero := range available.Heroes {
		if len(chosen.Heroes) >= required {
			break
		}
		if seen[hero.TableIdentifier] {
			continue
		}
		chosen.Heroes = append(chosen.Heroes, hero.Identifier)
		seen[hero.TableIdentifier] = true
	}
	if room.Turn >= SelectionPetTurn {
		slices.Sort(available.Pets)
		if len(available.Pets) != 0 {
			chosen.Pet = available.Pets[0]
		}
	}
	return room.advance(chosen, at), nil
}

func (room SelectionRoom) advance(chosen SelectedFormation, at time.Time) SelectionRoom {
	side := room.Turn % 2
	room.Teams[side][room.Team-1] = SelectedFormation{Heroes: slices.Clone(chosen.Heroes), Pet: chosen.Pet}
	room.Turn++
	if room.Turn == SelectionDoneTurn && room.Team < room.TeamCount() {
		room.Team++
		room.Turn = 0
	}
	room.Deadline = at.Add(SelectionTurnLifetime)
	return room
}

func (room SelectionRoom) TeamCount() int {
	if room.RequiredTeams == 0 {
		return SelectionTeamCount
	}
	return room.RequiredTeams
}
