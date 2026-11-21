//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// i912RawHero inserts one owned Hero and its raw awakening facet only: the
// ranking read needs the roster and that facet, not the other owner locals.
func i912RawHero(t *testing.T, p *pg.Pool, a identity.ActorContext, revision string, table, partner int64) {
	t.Helper()
	at := time.Now().UTC().Add(-time.Hour)
	h := character.Hero{PlayerID: a.PlayerID, PartnerID: partner, TableID: table, OriginTableID: table, Star: 5, Level: 1, Color: 1, CreationContentRevision: revision, RawSkills: character.NewHeroRawSkillSeed(), IllusionSkinID: character.DefaultIllusionSkinID, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	if e = (characterstore.Store{}).InsertHeroTx(ctx, tr, h); e != nil {
		t.Fatal(e)
	}
	if _, e = tr.Exec(ctx, `UPDATE player_hero_roots SET next_partner_id=GREATEST(next_partner_id,$2+1) WHERE player_id=$1`, int64(a.PlayerID), partner); e != nil {
		t.Fatal(e)
	}
	if e = (characterstore.RawAwakeningStore{}).InitFreshHeroTx(ctx, tr, h.Ref(), at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

func rankSubtypeDispatch(t *testing.T, dispatcher stockruntime.RankingDispatcher, actor identity.ActorContext, subtype int64) map[string]any {
	t.Helper()
	request := httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: 301, Operation: op(), ReceivedAt: time.Now().UTC(), Params: map[string]any{"rank_types": []any{subtype}}, Claims: wire.CredentialClaims{Token: string(actor.AccountUID), Region: int64(actor.LogicalServerID)}}}
	response := dispatcher.Dispatch(ctx, request)
	if response.HTTPStatus != 200 || response.Body["error_code"] != int64(0) {
		t.Fatalf("MID301 subtype %d status=%d body=%v", subtype, response.HTTPStatus, response.Body)
	}
	list, ok := response.Body["rank_list"].([]map[string]any)
	if !ok || len(list) != 1 || list[0]["rank_type"] != subtype {
		t.Fatalf("subtype %d rank list %v", subtype, response.Body)
	}
	info := list[0]["rank_info"].(map[string]any)
	// The checker marks my_rank.rank REQUIRED for every 301 reply, while R7 and
	// N8 serve the shaped empty {}. Check the ranked replies; report the gap.
	if mine, _ := info["my_rank"].(map[string]any); len(mine) > 0 {
		replyconformance.Check(t, 301, response.Body)
	}
	return info
}

func TestI912BloodAwakenAndOccultRankMID301(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := rankingServer(t, p)
	first := rankingActor(t, p, server, true)
	second := rankingActor(t, p, server, true)
	noScore := rankingActor(t, p, server, true)

	for partner, table := range map[int64]int64{1: 10001001, 2: 10001002, 3: 10001003} {
		i912RawHero(t, p, first, revision, table, partner)
		stage := int64(3)
		if partner == 3 {
			stage = 2
		}
		exec(t, p, `UPDATE player_hero_raw_awakening SET state_version=state_version+1,raw_stage=$3,producer_reference='I9_AWAKENING_MISSIONS_V1/i912-native',updated_at=clock_timestamp() WHERE player_id=$1 AND partner_id=$2`, int64(first.PlayerID), partner, stage)
	}

	exec(t, p, `INSERT INTO occult_players(player_id,logical_server_id,scores,payload_version,updated_at)VALUES($1,$2,'{"3":500}'::jsonb,1,clock_timestamp())`, int64(first.PlayerID), int64(server))
	exec(t, p, `INSERT INTO occult_players(player_id,logical_server_id,scores,payload_version,updated_at)VALUES($1,$2,'{"3":900}'::jsonb,1,clock_timestamp())`, int64(second.PlayerID), int64(server))

	service := rankingService(p, p)
	service.Comfort = dormstore.Store{Queryer: p}
	provider := privateMetricProvider(p)
	provider.Awakenings = characterstore.RawAwakeningStore{}
	service.BloodAwaken = provider
	service.Occult = occultstore.Store{}
	dispatcher := stockruntime.RankingDispatcher{Authority: bearerAuthority{string(first.AccountUID): first, string(second.AccountUID): second, string(noScore.AccountUID): noScore}, Service: service}

	blood := rankSubtypeDispatch(t, dispatcher, first, 14)
	rows := blood["rank_info"].([]map[string]any)
	if len(rows) != 1 || rows[0]["player_id"] != int64(first.PlayerID) || rows[0]["info_val"] != int64(2) || rows[0]["rank"] != int64(1) {
		t.Fatalf("blood awaken rows %v", blood)
	}
	mine := blood["my_rank"].(map[string]any)
	if mine["rank"] != int64(1) || mine["score"] != int64(2) {
		t.Fatalf("blood awaken my_rank %v", mine)
	}

	if _, e := service.ReadBoard(ctx, d.OccultChapterBoards[2], first, op()); e != nil {
		t.Fatal(e)
	}
	occult := rankSubtypeDispatch(t, dispatcher, second, 35)
	occultRows := occult["rank_info"].([]map[string]any)
	if len(occultRows) != 2 || occultRows[0]["player_id"] != int64(second.PlayerID) || occultRows[0]["point"] != int64(900) || occultRows[1]["player_id"] != int64(first.PlayerID) || occultRows[1]["point"] != int64(500) {
		t.Fatalf("occult chapter 3 rows %v", occult)
	}
	occultMine := occult["my_rank"].(map[string]any)
	if occultMine["rank"] != int64(1) || occultMine["point"] != int64(900) {
		t.Fatalf("occult my_rank %v", occultMine)
	}

	absent := rankSubtypeDispatch(t, dispatcher, noScore, 35)
	absentRows := absent["rank_info"].([]map[string]any)
	if len(absentRows) != 2 {
		t.Fatalf("a player without a chapter 3 best changed the board: %v", absent)
	}
	for _, row := range absentRows {
		if row["player_id"] == int64(noScore.PlayerID) {
			t.Fatalf("unscored player ranked with an invented zero: %v", absent)
		}
	}
	if len(absent["my_rank"].(map[string]any)) != 0 {
		t.Fatalf("unscored player got a rank: %v", absent)
	}

	purify := rankSubtypeDispatch(t, dispatcher, first, 13)
	if rows := purify["rank_info"].([]map[string]any); len(rows) != 0 || len(purify["my_rank"].(map[string]any)) != 0 {
		t.Fatalf("subtype 13 must stay a shaped empty 200: %v", purify)
	}
}
