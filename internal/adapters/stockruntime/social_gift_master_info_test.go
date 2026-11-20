package stockruntime

import (
	"context"
	"testing"
	"time"

	appmentor "gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	domainmentor "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

type giftMasterProbe struct{ result socialgift.Result }

func (p giftMasterProbe) Send(context.Context, identity.ActorContext, identity.PlayerID, operation.Context) (socialgift.Result, error) {
	return p.result, nil
}

func (giftMasterProbe) Claim(context.Context, identity.ActorContext, []socialinbox.NoticeID, operation.Context) (socialgift.Result, error) {
	return socialgift.Result{}, nil
}

func (giftMasterProbe) ReloadReferences(context.Context, identity.ActorContext, identity.PlayerID, socialgift.Result, operation.Context) ([]sr.ReloadReference, error) {
	return nil, nil
}

func giftMasterDispatcher(t *testing.T, result socialgift.Result) SocialDispatcher {
	t.Helper()
	return SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Gifts: giftMasterProbe{result: result}, giftStockReady: true, Scalar: &scalarProbe{}, Projection: unusedSocialProjection{}, Emitter: discardReloads{}}
}

func raisedClassBaseInfo(at time.Time) map[string]any {
	partner := identity.PlayerID(200001)
	cards := map[identity.PlayerID]playerpresentation.Projected{partner: {Minimal: playerpresentation.Minimal{PlayerID: partner, Name: "teacher", Level: 60, AvatarID: 110001001}}}
	info := appmentor.BuildClassInfo(appmentor.WireFacts{
		Now:       at,
		Actor:     100001,
		Relations: []domainmentor.Relationship{{Mentor: partner, Student: 100001, AcceptedAt: at, Intimacy: 100}},
		Cards:     cards,
	})
	return info["base_info"].(map[string]any)
}

func TestSocialGift183CarriesClassPairMasterInfo(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	request := heroReq(t, 183, map[string]any{"player_id": int64(200001)})
	response := giftMasterDispatcher(t, socialgift.Result{MasterInfo: raisedClassBaseInfo(at)}).Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 {
		t.Fatalf("status %d body %#v", response.HTTPStatus, response.Body)
	}
	replyconformance.Check(t, 183, response.Body)
	master, ok := response.Body["master_info"].(map[string]any)
	if !ok {
		t.Fatalf("master_info %#v", response.Body)
	}
	intimacies, ok := master["intimacies"].([]any)
	if !ok || len(intimacies) != 2 || intimacies[0] != int64(100) {
		t.Fatalf("raised intimacy %#v", master["intimacies"])
	}
}

func TestSocialGift183OmitsMasterInfoForNonClassPair(t *testing.T) {
	request := heroReq(t, 183, map[string]any{"player_id": int64(200001)})
	response := giftMasterDispatcher(t, socialgift.Result{}).Dispatch(context.Background(), request)
	if response.HTTPStatus != 200 || len(response.Body) != 0 {
		t.Fatalf("status %d body %#v", response.HTTPStatus, response.Body)
	}
	if _, present := response.Body["master_info"]; present {
		t.Fatalf("non-class pair carried master_info %#v", response.Body)
	}
}
