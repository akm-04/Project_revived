package illusion

import (
	"encoding/json"
	"testing"

	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
)

// A-176: the rank detail projects the frozen snapshot, so a live upgrade after
// the fight cannot change the level or star it shows.
func TestMemberTeamProjectsFrozenSnapshotHeroesAndPet(t *testing.T) {
	snapshot := cd.Snapshot{Battle: cd.Battle{
		TeamA: []cd.Actor{
			{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: 11, Identity: 101, Params: json.RawMessage(`{"partner_id":101,"lev":70,"star":5}`)},
			{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: 11, Identity: 102, Params: json.RawMessage(`{"partner_id":102,"lev":70,"star":4}`)},
			{Origin: cd.Borrowed, Kind: cd.HeroActor, Player: 12, Identity: 103, Params: json.RawMessage(`{"partner_id":103,"lev":90,"star":1}`)},
		},
		PetsA: []cd.Actor{
			{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: 11, Identity: 55, Params: json.RawMessage(`{"pet_id":55,"lev":52}`)},
		},
	}}
	heroes, pet := frozenMemberTeam(snapshot, identity.PlayerID(11), []int64{101, 103, 999})
	if len(heroes) != 1 || heroes[0]["partner_id"] != float64(101) || heroes[0]["lev"] != float64(70) || heroes[0]["star"] != float64(5) {
		t.Fatalf("frozen heroes %#v", heroes)
	}
	if pet == nil || pet["pet_id"] != float64(55) || pet["lev"] != float64(52) {
		t.Fatalf("frozen pet %#v", pet)
	}
	unreadable := cd.Snapshot{Battle: cd.Battle{TeamA: []cd.Actor{
		{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: 11, Identity: 101, Params: json.RawMessage(`{`)},
	}}}
	if heroes, pet = frozenMemberTeam(unreadable, identity.PlayerID(11), []int64{101}); len(heroes) != 0 || pet != nil {
		t.Fatalf("unreadable snapshot produced %#v %#v", heroes, pet)
	}
}
