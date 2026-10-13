package characterhero

import (
	"context"
	"errors"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type practiceContributionQueryer struct{}

func (practiceContributionQueryer) QueryRow(context.Context, string, ...any) tx.Row { return nil }

type heroPracticeContributionStore struct {
	hero  character.Hero
	calls int
}

func (s *heroPracticeContributionStore) ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error) {
	s.calls++
	return s.hero, nil
}

type heroPracticeContributionContent struct {
	good       bool
	revision   string
	tableID    int64
	thresholds []apppractice.Threshold
	err        error
}

func (c *heroPracticeContributionContent) PracticeRevisionTx(_ context.Context, _ tx.Queryer, revision string) (bool, error) {
	c.revision = revision
	if c.err != nil {
		return false, c.err
	}
	return c.good, nil
}
func (c *heroPracticeContributionContent) HeroPracticeThresholdsTx(_ context.Context, _ tx.Queryer, revision string, tableID int64) ([]apppractice.Threshold, error) {
	c.revision = revision
	c.tableID = tableID
	if c.err != nil {
		return nil, c.err
	}
	return append([]apppractice.Threshold(nil), c.thresholds...), nil
}

func heroPracticeContributionFixture() character.Hero {
	now := time.Unix(100, 0).UTC()
	rev := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	return character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: 7, PartnerID: 9, TableID: 10001003, OriginTableID: 10001003, Star: 1, Level: 1, Color: 1, Practice: character.PracticeAttrs{150, 160, 170}, CreationContentRevision: rev, StateVersion: 8, CreatedAt: now, UpdatedAt: now}
}

func TestHeroPracticeContributionReaderUsesAppliedOwnerStateAndPinnedRevision(t *testing.T) {
	h := heroPracticeContributionFixture()
	st := &heroPracticeContributionStore{hero: h}
	c := &heroPracticeContributionContent{good: true, thresholds: []apppractice.Threshold{{Ordinal: 1, NeedValue: 100, TargetAttrType: 20, BonusValue: 7}, {Ordinal: 2, NeedValue: 100, TargetAttrType: 20, BonusValue: 11}, {Ordinal: 3, NeedValue: 100, TargetAttrType: 2, BonusValue: 13}}}
	rev := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	got, err := (PracticeContributionReader{Store: st, Content: c}).HeroPracticeContributionTx(context.Background(), practiceContributionQueryer{}, 7, 9, rev)
	if err != nil {
		t.Fatal(err)
	}
	if c.revision != rev || c.tableID != h.TableID {
		t.Fatalf("content revision/table=%q/%d", c.revision, c.tableID)
	}
	if got.Family != characterasset.PracticeFamilyHero || got.OwnerID != 9 || got.TableID != h.TableID || got.StateVersion != 8 || got.ContentRevision != rev || got.Applied != h.Practice {
		t.Fatalf("got=%+v", got)
	}
	if got.Reducer != characterasset.PracticeReducerHeroAdditive || len(got.Contributions) != 4 {
		t.Fatalf("got=%+v", got)
	}
}

func TestHeroPracticeContributionReaderFailsBeforeOwnerReadWhenRevisionInactive(t *testing.T) {
	st := &heroPracticeContributionStore{hero: heroPracticeContributionFixture()}
	c := &heroPracticeContributionContent{good: false}
	_, err := (PracticeContributionReader{Store: st, Content: c}).HeroPracticeContributionTx(context.Background(), practiceContributionQueryer{}, 7, 9, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
	if !errors.Is(err, apppractice.ErrContentInactive) {
		t.Fatalf("err=%v", err)
	}
	if st.calls != 0 {
		t.Fatalf("owner read occurred before revision qualification: %d", st.calls)
	}
}
