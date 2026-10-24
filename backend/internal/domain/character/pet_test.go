package character

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func petFixture() Pet {
	now := time.Unix(100, 0).UTC()
	return Pet{
		PlayerID: identity.PlayerID(7), PetID: 3, TableID: 110030001, OriginTableID: 10030001,
		Star: 2, Level: 9, Exp: 123, Color: 1, Skills: DefaultPetSkillLevels(), Birthday: 1700000000, IsShow: true,
		CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		StateVersion:            2, CreatedAt: now, UpdatedAt: now,
	}
}

func TestPetIdentityAndSummaryRemainDistinct(t *testing.T) {
	p := petFixture()
	if err := p.ValidatePersistent(); err != nil {
		t.Fatal(err)
	}
	if p.PetID == p.TableID || p.TableID == p.OriginTableID {
		t.Fatalf("identity domains collapsed: %+v", p)
	}
	if got := p.Ref(); got.PlayerID != p.PlayerID || got.PetID != p.PetID {
		t.Fatalf("ref=%+v", got)
	}
	if got := p.Summary(); got.TableID != p.TableID || got.Star != p.Star || got.Color != p.Color {
		t.Fatalf("summary=%+v", got)
	}
}

func TestPetValidationRejectsUncollectedSentinelAndBadRevision(t *testing.T) {
	p := petFixture()
	p.PetID = -1
	if err := p.ValidatePersistent(); err == nil {
		t.Fatal("uncollected sentinel accepted as durable pet_id")
	}
	p = petFixture()
	p.CreationContentRevision = "REV"
	if err := p.ValidatePersistent(); err == nil {
		t.Fatal("bad content revision accepted")
	}
}

func TestPetValidationRejectsNegativeRawFumoButKeepsSlotsIndependent(t *testing.T) {
	p := petFixture()
	p.Fumo = PetFumoSlots{0, 17, 999}
	if err := p.ValidatePersistent(); err != nil {
		t.Fatalf("independent nonnegative raw Fumo rejected: %v", err)
	}
	p.Fumo[1] = -1
	if err := p.ValidatePersistent(); err == nil {
		t.Fatal("negative raw Pet Fumo accepted")
	}
}
