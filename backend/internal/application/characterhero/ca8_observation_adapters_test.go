package characterhero

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
)

func TestCA8HeroAdaptersNormalizeOnlyQualifiedInactive(t *testing.T) {
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	h := equipmentStateHero()
	eq := CA8EquipmentObservationAdapter{Reader: EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: equipmentStateContent{good: false, kind: character.NormalHero}}}
	gotEq, err := eq.HeroEquipmentObservationTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, rev)
	if err != nil || gotEq.Disposition != characterasset.ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("equipment=%+v err=%v", gotEq, err)
	}

	pst := &heroPracticeContributionStore{hero: heroPracticeContributionFixture()}
	pr := CA8PracticeObservationAdapter{Reader: PracticeContributionReader{Store: pst, Content: &heroPracticeContributionContent{good: false}}}
	gotPr, err := pr.HeroPracticeObservationTx(context.Background(), practiceContributionQueryer{}, 7, 9, rev)
	if err != nil || gotPr.Disposition != characterasset.ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("practice=%+v err=%v", gotPr, err)
	}

	ast := &heroAppearanceContributionStore{hero: heroAppearanceContributionFixture()}
	ap := CA8AppearanceObservationAdapter{Reader: AppearanceContributionReader{Store: ast, Content: &heroAppearanceContributionContent{active: false, kind: h.Kind}}}
	gotAp, err := ap.HeroAppearanceObservationTx(context.Background(), heroAppearanceContributionQueryer{}, 7, 9, rev, time.Unix(200, 0).UTC())
	if err != nil || gotAp.Disposition != characterasset.ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("appearance=%+v err=%v", gotAp, err)
	}
}

func TestCA8HeroAdapterPropagatesHardError(t *testing.T) {
	h := equipmentStateHero()
	h.Equipment[0] = 2
	eq := CA8EquipmentObservationAdapter{Reader: EquipmentStateReader{Store: equipmentStateStore{hero: h}, Content: equipmentStateContent{good: true, kind: character.NormalHero}}}
	_, err := eq.HeroEquipmentObservationTx(context.Background(), equipmentStateQueryer{}, h.PlayerID, h.PartnerID, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if err == nil || errors.Is(err, ErrHeroEquipmentContentInactive) {
		t.Fatalf("hard err=%v", err)
	}
}
