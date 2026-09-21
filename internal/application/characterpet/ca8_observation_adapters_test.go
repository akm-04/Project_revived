package characterpet

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
)

func TestCA8PetAdaptersNormalizeQualifiedInactive(t *testing.T) {
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	p := petEquipFixture()
	eq := CA8EquipmentObservationAdapter{Reader: EquipmentStateReader{Store: petEquipStore{p: p}, Content: &petEquipContent{good: false}}}
	gotEq, err := eq.PetEquipmentObservationTx(context.Background(), petEquipQ{}, p.PlayerID, p.PetID, rev)
	if err != nil || gotEq.Disposition != characterasset.ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("equipment=%+v err=%v", gotEq, err)
	}

	pst := &petPracticeContributionStore{pet: petPracticeContributionFixture()}
	pr := CA8PracticeObservationAdapter{Reader: PracticeContributionReader{Store: pst, Content: &petPracticeContributionContent{good: false}}}
	gotPr, err := pr.PetPracticeObservationTx(context.Background(), petPracticeContributionQueryer{}, 7, 12, rev)
	if err != nil || gotPr.Disposition != characterasset.ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("practice=%+v err=%v", gotPr, err)
	}

	ast := &petAppearanceContributionStore{pet: petAppearanceContributionFixture()}
	ap := CA8AppearanceObservationAdapter{Reader: AppearanceContributionReader{Store: ast, Content: &petAppearanceContributionContent{active: false}}}
	gotAp, err := ap.PetAppearanceObservationTx(context.Background(), petAppearanceContributionQueryer{}, 7, 12, rev, time.Unix(200, 0).UTC())
	if err != nil || gotAp.Disposition != characterasset.ProviderExplicitlyInactiveOrAbsent {
		t.Fatalf("appearance=%+v err=%v", gotAp, err)
	}
}
