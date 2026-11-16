package stockruntime

import (
	"context"
	"testing"

	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type giftClaimProbe struct {
	result socialgift.Result
	claims int
}

func (*giftClaimProbe) Send(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (socialgift.Result, error) {
	return socialgift.Result{}, nil
}

func (p *giftClaimProbe) Claim(context.Context, identity.ActorContext, []socialinbox.NoticeID, operation.Context) (socialgift.Result, error) {
	p.claims++
	return p.result, nil
}

func (*giftClaimProbe) ReloadReferences(context.Context, identity.ActorContext, identity.PlayerID, socialgift.Result, operation.Context) ([]sr.ReloadReference, error) {
	return nil, nil
}

type scalarProbe struct {
	amount int64
	calls  int
}

func (p *scalarProbe) CurrentScalar(context.Context, identity.PlayerID, string, operation.Context) (int64, error) {
	p.calls++
	return p.amount, nil
}

type unusedSocialProjection struct{}

func (unusedSocialProjection) LoadBase(context.Context, identity.ActorContext, operation.Context) (sp.Result, error) {
	return sp.Result{}, nil
}

func (unusedSocialProjection) LoadList(context.Context, identity.ActorContext, sp.ListKind, operation.Context) (sp.Result, error) {
	return sp.Result{}, nil
}

func (unusedSocialProjection) Search(context.Context, identity.ActorContext, sp.SearchQuery, operation.Context) (sp.Result, error) {
	return sp.Result{}, nil
}

func (unusedSocialProjection) Recommend(context.Context, identity.ActorContext, operation.Context) (sp.Result, error) {
	return sp.Result{}, nil
}

func giftClaimDispatcher(t *testing.T, gifts *giftClaimProbe, scalar *scalarProbe) SocialDispatcher {
	t.Helper()
	return SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Gifts: gifts, giftStockReady: true, Scalar: scalar, Projection: unusedSocialProjection{}, Emitter: discardReloads{}}
}

func TestSocialGiftClaimReplyShape(t *testing.T) {
	notice := socialinbox.NoticeID(42)
	request := heroReq(t, 184, map[string]any{"notice_ids": []any{int64(notice)}})

	t.Run("relation only omits awards sideband", func(t *testing.T) {
		gifts := &giftClaimProbe{result: socialgift.Result{NoticeIDs: []socialinbox.NoticeID{notice}}}
		scalar := &scalarProbe{amount: 5}
		response := giftClaimDispatcher(t, gifts, scalar).Dispatch(context.Background(), request)
		if response.HTTPStatus != 200 || gifts.claims != 1 {
			t.Fatalf("claim response %+v claims %d", response, gifts.claims)
		}
		if awards, present := response.Body["awards"]; present {
			t.Fatalf("relation-only claim emitted awards sideband: %#v", awards)
		}
		if response.Body["economy_"] != nil || scalar.calls != 0 {
			t.Fatalf("relation-only claim projected scalar: %#v calls %d", response.Body, scalar.calls)
		}
	})

	t.Run("gift settlement keeps awards and scalar", func(t *testing.T) {
		gifts := &giftClaimProbe{result: socialgift.Result{NoticeIDs: []socialinbox.NoticeID{notice}, Amount: 5}}
		scalar := &scalarProbe{amount: 5}
		response := giftClaimDispatcher(t, gifts, scalar).Dispatch(context.Background(), request)
		if response.HTTPStatus != 200 {
			t.Fatalf("claim response %+v", response)
		}
		awards, present := response.Body["awards"].([]any)
		if !present || len(awards) != 0 {
			t.Fatalf("gift settlement awards %#v", response.Body["awards"])
		}
		if economy, ok := response.Body["economy_"].(map[string]any); !ok || economy["friendship_coin"] != int64(5) || scalar.calls != 1 {
			t.Fatalf("gift settlement scalar %#v calls %d", response.Body["economy_"], scalar.calls)
		}
	})
}
