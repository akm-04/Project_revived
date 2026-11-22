package stockruntime

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/application/socialgift"
	dgift "gxb.local/backend/v2/internal/domain/socialgift"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type readinessContent struct {
	revisionErr error
	readErr     error
	content     socialgift.Content
}

func (r readinessContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	if r.revisionErr != nil {
		return "", r.revisionErr
	}
	return r.content.Revision, nil
}

func (r readinessContent) ReadGiftContent(context.Context, tx.Queryer, string) (socialgift.Content, error) {
	if r.readErr != nil {
		return socialgift.Content{}, r.readErr
	}
	return r.content, nil
}

type readinessQueryer struct{}

func (readinessQueryer) QueryRow(context.Context, string, ...any) tx.Row { return readinessRow{} }

type readinessRow struct{}

func (readinessRow) Scan(...any) error { return nil }

func readyGiftContent() socialgift.Content {
	vector := map[string]string{
		"arena_coin": "0", "badge": "0", "crystal": "0", "drops": "0", "energy": "0",
		"equip": "0", "ex_badge": "0", "exp": "0", "friendship_coin": "5", "item_nums": "0",
		"items": "0", "lucky_coin": "0", "mana": "0", "march_coin": "0", "skin_coin": "0",
		"skin_fragment": "0", "soul": "0", "spirit_energy": "", "summon_id": "0",
		"summon_init_time": "", "tutor_coin": "", "vip": "0", "vip_exp": "0",
	}
	raw, _ := json.Marshal(vector)
	digest := sha256.Sum256(append(raw, byte(10)))
	mapping := make([]dgift.SocialGiftMapping, 100)
	for i := range mapping {
		mapping[i] = dgift.SocialGiftMapping{Level: int64(i + 1), GiftID: int64(i + 1)}
	}
	return socialgift.Content{
		Revision: strings.Repeat("a", 64),
		Catalog: dgift.SocialGiftCatalog{
			SchemaVersion: 1, ResourceKey: "friendship_coin", Amount: 5,
			SendCap: 10, ClaimCap: 10, Policy: "SOCIAL_GIFT_DAY_V1",
			Selector: "UNKNOWN_UNIFORM_ONLY", VectorFingerprint: hex.EncodeToString(digest[:]),
			RewardVector: vector, Mapping: mapping,
		},
	}
}

func TestPreparedGiftStockEnablesType10ProducerOnlyAfterReadiness(t *testing.T) {
	readinessFailure := errors.New("catalog inactive")
	for _, test := range []struct {
		name    string
		content readinessContent
		ready   bool
	}{
		{name: "active revision error", content: readinessContent{revisionErr: readinessFailure}},
		{name: "gift content error", content: readinessContent{readErr: readinessFailure}},
		{name: "catalog invalid", content: readinessContent{content: socialgift.Content{Revision: strings.Repeat("a", 64)}}},
		{name: "catalog ready", content: readinessContent{content: readyGiftContent()}, ready: true},
	} {
		t.Run(test.name, func(t *testing.T) {
			activated := false
			group := PreparedGiftStock{prepared: true, content: test.content}
			group = group.BindType10Producer(func() { activated = true })
			dispatcher, err := group.Enable(context.Background(), readinessQueryer{})
			if (err == nil) != test.ready {
				t.Fatalf("readiness = %v, ready = %v", err, test.ready)
			}
			if activated != test.ready {
				t.Fatalf("type10 producer activated = %v after readiness = %v", activated, err)
			}
			if dispatcher.giftStockReady != test.ready {
				t.Fatalf("gift stock ready = %v, want %v", dispatcher.giftStockReady, test.ready)
			}
		})
	}
}

func TestUnpreparedGiftStockNeverActivatesType10Producer(t *testing.T) {
	activated := false
	group := PreparedGiftStock{type10: func() { activated = true }}
	if _, err := group.Enable(context.Background(), readinessQueryer{}); err == nil {
		t.Fatal("unprepared group enabled")
	}
	if activated {
		t.Fatal("unprepared group activated the type10 producer")
	}
}
