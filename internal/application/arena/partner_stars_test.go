package arena

import (
	"testing"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/character"
)

func TestAttachPartnerStarsUsesTheSubjectsCurrentStar(t *testing.T) {
	templates := d.Templates{10001001: {Base: 10001001}, 10001041: {Base: 10001040, Awakened: true}}
	usage := []d.Usage{{TableID: 10001001}, {TableID: 10001041}, {TableID: 10001099}}
	owned := []character.Hero{
		{PartnerID: 11, TableID: 10001001, Star: 3, Level: 1},
		{PartnerID: 12, TableID: 10001040, Star: 6, Level: 1},
	}
	attachPartnerStars(usage, owned, templates)
	if usage[0].Star == nil || *usage[0].Star != 3 {
		t.Fatalf("owned girl star = %v, want 3", usage[0].Star)
	}
	if usage[1].Star == nil || *usage[1].Star != 6 {
		t.Fatalf("awakened girl star = %v, want 6", usage[1].Star)
	}
	if usage[2].Star != nil {
		t.Fatalf("unowned girl star = %d, want omitted", *usage[2].Star)
	}
	owned[0].Star = 5
	attachPartnerStars(usage, owned, templates)
	if usage[0].Star == nil || *usage[0].Star != 5 {
		t.Fatalf("upgraded girl star = %v, want 5", usage[0].Star)
	}
}

func TestAttachPartnerStarsPicksTheStrongestOwnedCopy(t *testing.T) {
	templates := d.Templates{10001001: {Base: 10001001}}
	usage := []d.Usage{{TableID: 10001001}}
	owned := []character.Hero{
		{PartnerID: 11, TableID: 10001001, Star: 4, Level: 20},
		{PartnerID: 12, TableID: 10001001, Star: 4, Level: 30},
	}
	attachPartnerStars(usage, owned, templates)
	if usage[0].Star == nil || *usage[0].Star != 4 {
		t.Fatalf("star = %v, want 4", usage[0].Star)
	}
}
