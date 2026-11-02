package campaign

import (
	"context"
	"encoding/json"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type StoryHeroes interface {
	LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error
	AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error)
}
type Pets interface {
	LockCampaignPetTx(context.Context, tx.Tx, identity.PlayerID, int64) error
	CreditCampaignEXPTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, int64, string, time.Time) (character.Pet, error)
}
type liveBattle interface {
	LiveGenerationTx(context.Context, tx.Tx, cd.Locator, identity.PlayerID, string, time.Time) (bool, error)
}
type StoryChoice struct{ CampaignID, Type, Partner int64 }

func (s Mode) Bonus(c context.Context, a identity.ActorContext, kind int64, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "bonus", kind, op, func(c context.Context, sc gen.TimedScope, v view, r d.Record, _ int64, _ i5.PrivilegeSnapshot) (map[string]any, error) {
		if kind == d.Super && !v.superOpen {
			return nil, d.ErrRefused
		}
		next, b, err := v.catalog.ClaimBonus(r.Progress, kind)
		if err != nil {
			return nil, err
		}
		lines := itemLines(b.Items)
		if b.Crystal > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: b.Crystal})
		}
		if b.Mana > 0 {
			lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: b.Mana})
		}
		awards, err := s.grantAwards(c, sc, a, "bonus", lines)
		if err != nil {
			return nil, err
		}
		r.Progress = next
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, nil, sc.Operation.DecisionAt()); err != nil {
			return nil, err
		}
		return map[string]any{"chapter_info": v.catalog.Info(next, v.superOpen).Fields(), "awards": awardWire(awards)}, nil
	})
}

func itemLines(items [][2]int64) []grant.Line {
	lines := make([]grant.Line, 0, len(items))
	for _, i := range items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: i[0], Amount: i[1]})
	}
	return lines
}
func (s Mode) grantAwards(c context.Context, sc gen.TimedScope, a identity.ActorContext, name string, lines []grant.Line) ([]i5.Award, error) {
	current := sc.Operation.Operation()
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "campaign", Operation: name, BusinessKey: "campaign:" + name + ":" + current.ID.String(), Occurrence: current.ID.String(), PolicyVersion: d.PolicyID}, Lines: lines}
	out, err := s.Grants.SettleGrantTx(c, sc.Tx, a, plan, current, i5.GrantTxOptions{})
	return out.Awards, err
}

func (s Mode) ChapterAward(c context.Context, a identity.ActorContext, chapter int64, op operation.Context) (map[string]any, error) {
	return s.purchase(c, a, "chapter-award", chapter, op, func(c context.Context, sc gen.TimedScope, v view, r d.Record, _ int64, _ i5.PrivilegeSnapshot) (map[string]any, error) {
		next, items, err := v.catalog.ClaimChapter(r.Progress, chapter)
		if err != nil {
			return nil, err
		}
		awards, err := s.grantAwards(c, sc, a, "chapter-award", itemLines(items))
		if err != nil {
			return nil, err
		}
		r.Progress = next
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, nil, sc.Operation.DecisionAt()); err != nil {
			return nil, err
		}
		return map[string]any{"awards": awardWire(awards), "chapter_event": v.catalog.ChapterEvent(next, chapter)}, nil
	})
}

func (s Mode) StoryAward(c context.Context, a identity.ActorContext, q StoryChoice, op operation.Context) (map[string]any, error) {
	if s.StoryHeroes == nil || s.StoryWire == nil {
		return nil, d.ErrUnavailable
	}
	return s.purchase(c, a, "story-award", q, op, func(c context.Context, sc gen.TimedScope, v view, r d.Record, _ int64, _ i5.PrivilegeSnapshot) (map[string]any, error) {
		n, found := v.catalog.Node(q.CampaignID)
		if !found || n.Type != d.Normal || q.Type != d.Normal {
			return nil, d.ErrInvalid
		}
		valid := false
		for _, id := range n.StoryPartners {
			valid = valid || id == q.Partner
		}
		if !valid {
			return nil, d.ErrInvalid
		}
		if prior := r.Progress.StoryClaims[n.ID]; len(prior) > 0 {
			var saved storyClaim
			err := json.Unmarshal(prior, &saved)
			if err == nil && saved.Body == nil {
				err = d.ErrUnavailable
			}
			return saved.Body, err
		}
		battle, ok := s.Combat.(liveBattle)
		if !ok {
			return nil, d.ErrUnavailable
		}
		live, err := battle.LiveGenerationTx(c, sc.Tx, locator(a), a.PlayerID, generation(q.Type, q.CampaignID), sc.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		if !live || r.PendingGeneration != generation(q.Type, q.CampaignID) || r.Progress.State(n.ID).PartnerDrop {
			return nil, d.ErrRefused
		}
		h, admission, err := s.StoryHeroes.AwardStoryPartnerTx(c, sc.Tx, a.PlayerID, q.Partner, v.revision, sc.Operation.Operation())
		if err != nil {
			return nil, err
		}
		award, err := s.StoryWire(h)
		if err != nil {
			return nil, err
		}
		award["is_partner"] = true
		body := map[string]any{"story_drop_awards": []any{award}}
		raw, err := json.Marshal(storyClaim{Body: body, Admission: admission})
		if err != nil {
			return nil, err
		}
		claims := make(map[int64]json.RawMessage, len(r.Progress.StoryClaims)+1)
		for id, row := range r.Progress.StoryClaims {
			claims[id] = row
		}
		claims[n.ID] = raw
		r.Progress.StoryClaims = claims
		state := r.Progress.State(n.ID)
		state.PartnerDrop = true
		r.Progress = r.Progress.WithNode(state)
		if err = s.Store.SaveTx(c, sc.Tx, a.PlayerID, r, []int64{n.ID}, sc.Operation.DecisionAt()); err != nil {
			return nil, err
		}
		return body, nil
	})
}

func (s Mode) Caps(c context.Context, a identity.ActorContext, op operation.Context) (map[string]any, error) {
	op, err := s.pin(c, op)
	if err != nil {
		return nil, err
	}
	if s.MaxColor == nil {
		return nil, d.ErrUnavailable
	}
	var out map[string]any
	_, _, err = s.Timed.Run(c, op, ModeProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, retry(), nil, func(c context.Context, sc gen.TimedScope) error {
		revision, _ := op.Policies.Get("content")
		p, err := s.Content.ResolveProgressionPolicyTx(c, sc.Tx, revision)
		if err != nil {
			return err
		}
		color, err := s.MaxColor.MaxHeroColorTx(c, sc.Tx, a.PlayerID, sc.Operation.Operation())
		if err != nil {
			return err
		}
		out = map[string]any{"max_lev": p.MaxLevel(), "max_color": color}
		return nil
	})
	return out, err
}

// awardWire follows AlertAwardWindow: scalar rows use table_id -1 and the
// resource name as a key, while positive item identities remain ordinary items.
func awardWire(awards []i5.Award) []any {
	rows := make([]any, 0, len(awards))
	for _, a := range awards {
		row := map[string]any{"table_id": a.TableID, "item_num": a.ItemNum}
		if a.ResourceKey != "" {
			row["table_id"] = int64(-1)
			row[a.ResourceKey] = a.ItemNum
		}
		rows = append(rows, row)
	}
	return rows
}

// storyClaim retains internal admission provenance without exposing it on the wire.
type storyClaim struct {
	Body      map[string]any                      `json:"body"`
	Admission *character.CollectionAdmissionProof `json:"admission,omitempty"`
}
