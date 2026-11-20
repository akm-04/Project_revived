package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"testing"

	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type searchProjectionProbe struct {
	unusedSocialProjection
	err error
}

func (p searchProjectionProbe) Search(context.Context, identity.ActorContext, sp.SearchQuery, operation.Context) (sp.Result, error) {
	return sp.Result{}, p.err
}

func saturatedDispatcher(t *testing.T, err error) SocialDispatcher {
	t.Helper()
	return SocialDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Projection: searchProjectionProbe{err: err}}
}

func TestSocialSaturatedSearchIsTypedRefusal(t *testing.T) {
	request := heroReq(t, 188, map[string]any{"msg": "same-name"})
	response := saturatedDispatcher(t, sp.ErrSearchSaturated).Dispatch(context.Background(), request)
	if response.HTTPStatus != http.StatusConflict || response.Body["error_code"] != int64(35028) {
		t.Fatalf("saturated search status %d body %#v", response.HTTPStatus, response.Body)
	}
}

func TestSocialRealDatabaseFailureStaysDefect(t *testing.T) {
	request := heroReq(t, 188, map[string]any{"msg": "same-name"})
	response := saturatedDispatcher(t, errors.New("database unavailable")).Dispatch(context.Background(), request)
	if response.HTTPStatus != http.StatusInternalServerError || response.Body["error_code"] != int64(35028) {
		t.Fatalf("database failure status %d body %#v", response.HTTPStatus, response.Body)
	}
}
