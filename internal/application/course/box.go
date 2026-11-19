package course

import (
	"context"
	"strconv"

	i5 "gxb.local/backend/v2/internal/application/i5"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// applyGiftBox consumes the day's free box flag or one owned box item, rolls
// the box dropbox and answers the post-claim availability flag.
func (s Service) applyGiftBox(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, root course.Root) (map[string]any, error) {
	at := d.DecisionAt
	rule, found, e := s.Content.CourseGiftBoxRuleTx(ctx, t, d.ContentRevision, d.Command.ItemID)
	if e != nil {
		return nil, e
	}
	if !found || rule.ItemID != d.Command.ItemID {
		return nil, course.ErrInvalid
	}
	today := modes.Day(at)
	free := d.Command.ItemID == course.DailyGiftBoxItemID && root.GiftBoxDay != today
	valueOperation := d.Operation
	valueOperation.StartedAt = at
	if !free {
		cost := i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: d.Command.ItemID, Amount: 1}}}
		prepared, e := s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, cost, valueOperation)
		if e != nil {
			return nil, e
		}
		if _, e = s.Costs.ApplyMaterialDebitTx(ctx, t, prepared); e != nil {
			return nil, e
		}
	}
	if free {
		if e = s.Owner.ClaimGiftBoxDayTx(ctx, t, a.PlayerID, today, at); e != nil {
			return nil, e
		}
		root.GiftBoxDay = today
	}
	drop, e := rule.Roll(valueOperation)
	if e != nil {
		return nil, e
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "course", Operation: "gift-box", BusinessKey: "course:gift-box:" + strconv.FormatInt(d.Command.ItemID, 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: drop.ItemID, Amount: drop.ItemNum}}}
	result, e := s.Grants.SettleGrantTx(ctx, t, a, plan, valueOperation, i5.GrantTxOptions{AllowOverflowMail: true})
	if e != nil {
		return nil, e
	}
	return map[string]any{"awards": giftBoxAwards(result.Awards), "is_has_gift": giftBoxFlag(root.GiftBoxDay != today)}, nil
}

func giftBoxAwards(awards []i5.Award) []any {
	rows := make([]any, 0, len(awards))
	for _, award := range awards {
		rows = append(rows, map[string]any{"table_id": award.TableID, "item_num": award.ItemNum})
	}
	return rows
}

func giftBoxFlag(available bool) int64 {
	if available {
		return 1
	}
	return 0
}
