package stockruntime

import (
	"context"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func publicProfileFailureService(t *testing.T, failure error) PublicProfileReadDispatcher {
	t.Helper()
	a := actorForHTTP(t)
	return PublicProfileReadDispatcher{
		Authority: httpAuthority{a},
		Service: profileReadsFunc(func(context.Context, identity.ActorContext, publicprofile.ReadRequest, operation.Context) (map[string]any, error) {
			return nil, failure
		}),
	}
}

func TestA121PrivacyDenialsAreRefusals(t *testing.T) {
	cases := []struct {
		mid    uint16
		params map[string]any
		denial error
	}{
		{1829, map[string]any{"to_player_id": int64(100002), "sub_type": int64(2)}, publicprofile.ErrShowcasePrivate},
		{1838, map[string]any{"to_player_id": int64(100002), "index": int64(1)}, publicprofile.ErrEmptyShowcase},
	}
	for _, tc := range cases {
		d := publicProfileFailureService(t, tc.denial)
		got := d.Dispatch(context.Background(), activityReq(tc.mid, tc.params, time.Now()))
		if got.HTTPStatus != 409 {
			t.Fatalf("MID %d privacy denial status %d %+v", tc.mid, got.HTTPStatus, got)
		}
		if got.Body["error_code"] != int64(35028) || got.Body["error_msg"] != "" {
			t.Fatalf("MID %d refusal body %+v", tc.mid, got.Body)
		}
		if len(got.Body) != 2 {
			t.Fatalf("MID %d refusal carries fields %+v", tc.mid, got.Body)
		}
	}
}

func TestA121ProfileProviderFaultsStayDefects(t *testing.T) {
	cases := []struct {
		mid     uint16
		params  map[string]any
		failure error
	}{
		{1829, map[string]any{"to_player_id": int64(100002), "sub_type": int64(2)}, publicprofile.ErrProfileProvider},
		{1838, map[string]any{"to_player_id": int64(100002), "index": int64(1)}, publicprofile.ErrShowcaseUnavailable},
	}
	for _, tc := range cases {
		d := publicProfileFailureService(t, tc.failure)
		got := d.Dispatch(context.Background(), activityReq(tc.mid, tc.params, time.Now()))
		if got.HTTPStatus != 500 {
			t.Fatalf("MID %d provider fault status %d %+v", tc.mid, got.HTTPStatus, got)
		}
	}
}
