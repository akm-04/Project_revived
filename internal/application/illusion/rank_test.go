package illusion

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// rankOnlyStore leaves every other Store method to the embedded interface; the
// board read only calls RankOfTx on this path.
type rankOnlyStore struct {
	Store
	rank int64
}

func (s rankOnlyStore) RankOfTx(context.Context, tx.Queryer, int64, int64, identity.PlayerID) (int64, error) {
	return s.rank, nil
}

func TestPlayerBoardUsesStoreRankBeyondReadWindow(t *testing.T) {
	mode := Mode{Store: rankOnlyStore{rank: 1001}}
	body, err := mode.playerBoard(context.Background(), identity.ActorContext{PlayerID: 100001}, d.RankPersonal, nil, 1, 1)
	if err != nil {
		t.Fatal(err)
	}
	info := body["rank_list"].([]map[string]any)[0]["rank_info"].(map[string]any)
	entry, ok := info["my_rank"].(map[string]any)
	if !ok || entry["rank"] != int64(1001) {
		t.Fatalf("my_rank = %#v, want rank 1001 from the store", info["my_rank"])
	}
}
