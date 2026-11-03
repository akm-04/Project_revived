package librarylocal

import (
	"context"
	"strconv"

	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// claimSchoolStoryTx inserts the once-per-player claim before paying the row's
// stack item and scalar gold/diamond awards.
func (s Service) claimSchoolStoryTx(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission, catalog lib.Catalog) ([]i5.Award, error) {
	talk, ok := catalog.Talks[d.Command.Value]
	if !ok {
		return nil, lib.ErrUnqualified
	}
	if s.Grants == nil {
		return nil, ErrUnavailable
	}
	inserted, e := s.Library.InsertTalkClaimTx(ctx, t, lib.TalkClaimFact{PlayerID: a.PlayerID, TalkID: talk.ID, ClaimedAt: d.DecisionAt})
	if e != nil {
		return nil, e
	}
	if !inserted {
		return nil, lib.ErrTalkClaimed
	}
	lines := make([]grant.Line, 0, 3)
	if talk.ItemID > 0 && talk.ItemNum > 0 {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: talk.ItemID, Amount: talk.ItemNum})
	}
	if talk.Gold > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: talk.Gold})
	}
	if talk.Diamond > 0 {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: talk.Diamond})
	}
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "library", Operation: "school-story", BusinessKey: "library:school-story:" + strconv.FormatInt(talk.ID, 10), Occurrence: d.Operation.ID.String(), PolicyVersion: LifecyclePolicy}, Lines: lines}
	result, e := s.Grants.SettleGrantTx(ctx, t, a, plan, d.Operation, i5.GrantTxOptions{AllowOverflowMail: true})
	if e != nil {
		return nil, e
	}
	return result.Awards, nil
}

// StockAwardRows follows the stock award row shape: item lines keep their
// table_id, scalar lines use -1 plus the resource key.
func StockAwardRows(awards []i5.Award) []any {
	rows := make([]any, 0, len(awards))
	for _, award := range awards {
		row := map[string]any{"table_id": award.TableID, "item_num": award.ItemNum}
		if award.ResourceKey != "" {
			row["table_id"] = int64(-1)
			row[award.ResourceKey] = award.ItemNum
		}
		rows = append(rows, row)
	}
	return rows
}
