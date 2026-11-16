package stockruntime

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialpresence"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type relationMutationProbe struct{ result sr.Result }

type discardReloads struct{}

func (discardReloads) Emit(context.Context, []sr.ReloadReference) {}

func (p relationMutationProbe) Execute(context.Context, identity.ActorContext, sr.Command, operation.Context) (sr.Result, error) {
	return p.result, nil
}

func mutationResponse(t *testing.T, mid uint16, result sr.Result) map[string]any {
	t.Helper()
	dispatcher := SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Relations: relationMutationProbe{result: result}, Emitter: discardReloads{}}
	response := dispatcher.Dispatch(context.Background(), heroReq(t, mid, map[string]any{"player_id": int64(200001)}))
	if response.HTTPStatus != 200 {
		t.Fatalf("mid %d status %d %#v", mid, response.HTTPStatus, response.Body)
	}
	raw, err := json.Marshal(response.JSON)
	if err != nil {
		t.Fatal(err)
	}
	var body map[string]any
	if err = json.Unmarshal(raw, &body); err != nil {
		t.Fatal(err)
	}
	return body
}

func TestSocialMutationRepliesCarryProjectedPlayer(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	target := identity.PlayerID(200001)
	projected := playerpresentation.Projected{Minimal: playerpresentation.Minimal{PlayerID: target, Name: "peer", Level: 9, AvatarID: 4, AvatarFrameID: 5}, Presence: socialpresence.Observation{PlayerID: target, IsOnline: true, LatestConnectedAt: &at}}
	result := sr.Result{Players: playerpresentation.Batch{ObservedAt: at, Players: map[identity.PlayerID]playerpresentation.Projected{target: projected}}}

	// MID 177: SendRequestPlayers populates a NonFriendPlayer from the reply's top-level row.
	request := mutationResponse(t, 177, result)
	if request["player_id"] != float64(target) || request["player_name"] != "peer" || request["lev"] != float64(9) {
		t.Fatalf("177 row %#v", request)
	}

	// MID 185: PersonDisplayWindow inserts reply.player_info into its open blacklist.
	blocked := mutationResponse(t, 185, result)
	playerInfo, ok := blocked["player_info"].(map[string]any)
	if !ok || playerInfo["player_id"] != float64(target) || playerInfo["player_name"] != "peer" || playerInfo["lev"] != float64(9) || playerInfo["avatar_id"] != float64(4) || playerInfo["avatar_frame_id"] != float64(5) || playerInfo["conquer_lev"] == nil || playerInfo["conquer_loop_id"] == nil || playerInfo["is_online"] == nil || playerInfo["last_time"] == nil {
		t.Fatalf("185 player_info %#v", blocked)
	}
}
