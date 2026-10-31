package illusion

import "fmt"

type Hero struct {
	TableID int64 `json:"table_id"`
	Power   int64 `json:"power"`
}

// TeamMember is one frozen seat; Members[0] is the master.
type TeamMember struct {
	PlayerID int64  `json:"player_id"`
	Level    int64  `json:"level"`
	Force    int64  `json:"force"`
	Heroes   []Hero `json:"heroes"`
	PetID    int64  `json:"pet_id"`
}

type Team struct {
	Members []TeamMember `json:"members"`
}

// Validate enforces C5: three seats, master one hero and optional pet, mates
// two heroes and no pets, unique hero table ids, power at least force/30, and
// academy level 65 within five levels of the master.
func (t Team) Validate() error {
	if len(t.Members) != TeamSeats {
		return fmt.Errorf("%w: three seats", ErrRefused)
	}
	master := t.Members[0]
	seenPlayers := map[int64]bool{}
	seenHeroes := map[int64]bool{}
	for index, member := range t.Members {
		if member.PlayerID <= 0 || seenPlayers[member.PlayerID] || member.Level < OpenLevel || member.Force < 0 || member.PetID < 0 {
			return fmt.Errorf("%w: seat %d identity", ErrRefused, index)
		}
		seenPlayers[member.PlayerID] = true
		if member.Level < master.Level-TeamLevelBand || member.Level > master.Level+TeamLevelBand {
			return fmt.Errorf("%w: seat %d level band", ErrRefused, index)
		}
		heroes := MasterHeroes
		if index > 0 {
			heroes = MateHeroes
			if member.PetID != 0 {
				return fmt.Errorf("%w: mate pet", ErrRefused)
			}
		}
		if len(member.Heroes) != heroes {
			return fmt.Errorf("%w: seat %d hero count", ErrRefused, index)
		}
		powerFloor := member.Force / TeamPowerLimit
		for _, hero := range member.Heroes {
			if hero.TableID <= 0 || seenHeroes[hero.TableID] || hero.Power < powerFloor {
				return fmt.Errorf("%w: seat %d hero", ErrRefused, index)
			}
			seenHeroes[hero.TableID] = true
		}
	}
	if len(seenHeroes) != TeamHeroLimit {
		return fmt.Errorf("%w: hero total", ErrRefused)
	}
	return nil
}
