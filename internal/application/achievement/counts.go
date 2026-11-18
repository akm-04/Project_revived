package achievement

import (
	"context"
	book "gxb.local/backend/v2/internal/application/bookskill"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	course "gxb.local/backend/v2/internal/application/course"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	ins "gxb.local/backend/v2/internal/application/inscription"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/character"
	conquer "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type HeroKinds interface {
	ReadPlayerDisplayCatalogTx(context.Context, tx.Queryer, string) (player.DisplayCatalog, error)
}
type Books interface {
	BookInputsTx(context.Context, tx.Queryer, book.InputScope) (book.Inputs, error)
}
type Conquer interface {
	FactsTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (conquer.Observation, error)
}
type Courses interface {
	CompletedCourseCountTx(context.Context, tx.Queryer, course.InputScope) (int64, error)
}
type Inscriptions interface {
	CompleteSuitCountTx(context.Context, tx.Queryer, ins.InputScope) (int64, error)
}
type Skins interface {
	SkinCollectionTx(context.Context, ca.CoherentReadScope, identity.PlayerID) (display.CosmeticCount, error)
}
type Dorm interface {
	VillaCountTx(context.Context, tx.Queryer, dorm.InputScope) (dorm.VillaInputs, error)
}
type GuildCampaign interface {
	BestDamageTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}
type PetCampaign interface {
	MaxFloorTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}
type Campaign interface {
	MainChainStarsTx(context.Context, tx.Queryer, identity.PlayerID, string) (int64, error)
}
type SchoolStory interface {
	SchoolStoryCountTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}
type Mentor interface {
	GraduatedCountTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}
type Memoir interface {
	TenthFloorTx(context.Context, tx.Queryer, identity.PlayerID) (int64, error)
}
type Occult interface {
	ClearedChapterCountTx(context.Context, tx.Queryer, identity.PlayerID, string) (int64, error)
}

// OwnerCounts reads C4F_OWNED_STATE_COUNT_V1 values through each owner's typed
// read port in one coherent scope. An unavailable owner read leaves that
// achievement unobserved (never zero-filled); the next observation catches up.
type OwnerCounts struct {
	Roster        ca.RosterMetricReader
	Kinds         HeroKinds
	Books         Books
	Conquer       Conquer
	Courses       Courses
	Inscriptions  Inscriptions
	Dorm          Dorm
	Skins         Skins
	GuildCampaign GuildCampaign
	PetCampaign   PetCampaign
	Campaign      Campaign
	SchoolStories SchoolStory
	Mentor        Mentor
	Memoir        Memoir
	Occult        Occult
}

func (o OwnerCounts) OwnedStateCountsTx(c context.Context, sc ca.CoherentReadScope, p identity.PlayerID, families []int64) map[int64]int64 {
	out := map[int64]int64{}
	wanted := map[int64]bool{}
	for _, id := range families {
		wanted[id] = true
	}
	q := sc.Queryer()
	heroes, heroesErr := o.Roster.ReadRosterMetricsTx(c, sc, p, "Hero")
	catalog, kindsErr := o.Kinds.ReadPlayerDisplayCatalogTx(c, q, sc.ContentRevision)
	heroesKnown := heroesErr == nil && kindsErr == nil
	kinds := map[int64]string{}
	for _, t := range catalog.HeroTemplates {
		kinds[t.TableID] = t.Kind
	}
	if heroesKnown && (wanted[d.NormalHeroesID] || wanted[d.AwakenedHeroesID]) {
		normal := map[int64]bool{}
		for _, h := range heroes.Rows {
			if kinds[h.TableID] == string(character.NormalHero) {
				normal[h.OriginTableID] = true
			}
			if h.BeforeAwaken > 0 {
				out[d.AwakenedHeroesID]++
			}
		}
		out[d.NormalHeroesID] = int64(len(normal))
	}
	if wanted[d.PetsID] {
		if pets, e := o.Roster.ReadRosterMetricsTx(c, sc, p, "Pet"); e == nil {
			out[d.PetsID] = int64(len(pets.Rows))
		}
	}
	if wanted[d.TextbooksID] {
		if v, e := o.Books.BookInputsTx(c, q, book.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}); e == nil {
			total := int64(0)
			for _, level := range v.Applied.Skills {
				total += level
			}
			out[d.TextbooksID] = total
		}
	}
	if wanted[d.RegionsID] {
		if v, e := o.Conquer.FactsTx(c, sc, p); e == nil {
			out[d.RegionsID] = v.Regions
		}
	}
	if wanted[d.SkinsID] && o.Skins != nil {
		if v, e := o.Skins.SkinCollectionTx(c, sc, p); e == nil {
			out[d.SkinsID] = v.Value
		}
	}
	if wanted[d.RoomsID] || wanted[d.ExpandedRoomsID] {
		if v, e := o.Dorm.VillaCountTx(c, q, dorm.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}); e == nil {
			out[d.RoomsID], out[d.ExpandedRoomsID] = v.Rooms, v.Expanded
		}
	}
	if heroesKnown && wanted[d.TitanID] {
		titans := int64(0)
		for _, h := range heroes.Rows {
			if kinds[h.TableID] == string(character.SuperHero) {
				titans++
			}
		}
		out[d.TitanID] = titans
	}
	if wanted[d.GuildDamageID] && o.GuildCampaign != nil {
		if damage, e := o.GuildCampaign.BestDamageTx(c, q, p); e == nil {
			out[d.GuildDamageID] = damage / d.GuildDamagePerTenThousand
		}
	}
	if wanted[d.SkyTowerID] && o.PetCampaign != nil {
		if floor, e := o.PetCampaign.MaxFloorTx(c, q, p); e == nil {
			out[d.SkyTowerID] = floor
		}
	}
	if wanted[d.CampaignStarsID] && o.Campaign != nil {
		if stars, e := o.Campaign.MainChainStarsTx(c, q, p, sc.ContentRevision); e == nil {
			out[d.CampaignStarsID] = stars
		}
	}
	if wanted[d.SchoolStoriesID] && o.SchoolStories != nil {
		if n, e := o.SchoolStories.SchoolStoryCountTx(c, q, p); e == nil {
			out[d.SchoolStoriesID] = n
		}
	}
	if wanted[d.GraduatedStudentsID] && o.Mentor != nil {
		if n, e := o.Mentor.GraduatedCountTx(c, q, p); e == nil {
			out[d.GraduatedStudentsID] = n
		}
	}
	if wanted[d.MemoirFloorsID] && o.Memoir != nil {
		if floor, e := o.Memoir.TenthFloorTx(c, q, p); e == nil {
			out[d.MemoirFloorsID] = floor
		}
	}
	if wanted[d.OccultChaptersID] && o.Occult != nil {
		if n, e := o.Occult.ClearedChapterCountTx(c, q, p, sc.ContentRevision); e == nil {
			out[d.OccultChaptersID] = n
		}
	}
	if !heroesKnown {
		return out
	}
	if wanted[d.SubjectsID] {
		if n, e := o.Courses.CompletedCourseCountTx(c, q, course.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}); e == nil {
			out[d.SubjectsID] = n
		}
	}
	if wanted[d.SuitsID] {
		if n, e := o.Inscriptions.CompleteSuitCountTx(c, q, ins.InputScope{Player: p, ContentRevision: sc.ContentRevision, ObservedAt: sc.ObservedAt}); e == nil {
			out[d.SuitsID] = n
		}
	}
	return out
}
