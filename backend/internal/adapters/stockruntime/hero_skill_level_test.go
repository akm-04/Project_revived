package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"reflect"
	"strings"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

type heroSkillLevelDispatchStub struct {
	singleResult  apphero.HeroSkillLevelResult
	bulkResult    apphero.HeroSkillLevelResult
	bulkErr       error
	view          apphero.HeroSkillLevelView
	viewErr       error
	partnerID     int64
	skillIndex    int64
	bulkPartnerID int64
	changes       []apphero.HeroSkillLevelChange
}

func (stub *heroSkillLevelDispatchStub) SetSkillLevel(_ context.Context, _ identity.ActorContext, partnerID, skillIndex int64, _ operation.Context) (apphero.HeroSkillLevelResult, error) {
	stub.partnerID = partnerID
	stub.skillIndex = skillIndex
	return stub.singleResult, nil
}

func (stub *heroSkillLevelDispatchStub) SetAllSkillLevels(_ context.Context, _ identity.ActorContext, partnerID int64, changes []apphero.HeroSkillLevelChange, _ operation.Context) (apphero.HeroSkillLevelResult, error) {
	stub.bulkPartnerID = partnerID
	stub.changes = changes
	return stub.bulkResult, stub.bulkErr
}

func (stub *heroSkillLevelDispatchStub) SkillLevelView(context.Context, identity.ActorContext, int64, operation.Context) (apphero.HeroSkillLevelView, error) {
	return stub.view, stub.viewErr
}

func heroSkillLevelRefusalFields(t *testing.T, response httpedge.Response, wantStatus int, wantCode int64) {
	t.Helper()
	if response.HTTPStatus != wantStatus || response.Body["error_code"] != wantCode {
		t.Fatalf("refusal status %d code %v, want %d/%d: %#v", response.HTTPStatus, response.Body["error_code"], wantStatus, wantCode, response.Body)
	}
	if response.Body["skills"] != "3|2|1|1|1|1" || response.Body["is_success"] != int64(0) || response.Body["skill_point"] != int64(6) || response.Body["skill_time"] != int64(1700000100) {
		t.Fatalf("MID 39 refusal lost its C2 fields: %#v", response.Body)
	}
}

func TestHeroSkillLevelMIDsWireSuccessAndPrivateRefusal(t *testing.T) {
	stub := &heroSkillLevelDispatchStub{
		singleResult: apphero.HeroSkillLevelResult{SkillLevels: [6]int64{2, 1, 1, 1, 1, 1}, SkillPoint: 8, SkillTime: 1700000000, Success: true},
		bulkResult:   apphero.HeroSkillLevelResult{SkillLevels: [6]int64{3, 2, 1, 1, 1, 1}, SkillPoint: 6, SkillTime: 1700000100, Success: true},
	}
	dispatcher := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, SkillLevels: stub}

	single := dispatcher.Dispatch(context.Background(), heroReq(t, 53, map[string]any{"partner_id": int64(7), "skill_index": int64(2)}))
	if single.HTTPStatus != http.StatusOK || single.Body["skill_point"] != int64(8) || single.Body["skill_time"] != int64(1700000000) || stub.partnerID != 7 || stub.skillIndex != 2 {
		t.Fatal("MID 53 success", single, stub)
	}

	bulk := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": "2|1", "skill_counts": "1|2"}))
	wantChanges := []apphero.HeroSkillLevelChange{{Slot: 2, Count: 1}, {Slot: 1, Count: 2}}
	if bulk.HTTPStatus != http.StatusOK || bulk.Body["skills"] != "3|2|1|1|1|1" || bulk.Body["is_success"] != int64(1) || stub.bulkPartnerID != 9 || !reflect.DeepEqual(stub.changes, wantChanges) {
		t.Fatal("MID 39 success", bulk, stub)
	}

	oneSkill := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": json.Number("3"), "skill_counts": float64(8)}))
	if oneSkill.HTTPStatus != http.StatusOK || !reflect.DeepEqual(stub.changes, []apphero.HeroSkillLevelChange{{Slot: 3, Count: 8}}) {
		t.Fatal("MID 39 one-skill bulk sent as bare numbers", oneSkill, stub)
	}

	stub.singleResult.Success = false
	singleRefusal := dispatcher.Dispatch(context.Background(), heroReq(t, 53, map[string]any{"partner_id": int64(7), "skill_index": int64(2)}))
	if singleRefusal.HTTPStatus != http.StatusConflict || singleRefusal.Body["error_code"] != unprovenRefusalCode || singleRefusal.Body["skill_point"] != int64(8) {
		t.Fatal("MID 53 refusal", singleRefusal)
	}

	stub.bulkResult.Success = false
	stub.bulkResult.RefusalReason = apphero.HeroSkillLevelRefusalNoChange
	bulkRefusal := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": "2|1", "skill_counts": "1|2"}))
	if bulkRefusal.HTTPStatus != http.StatusConflict || bulkRefusal.Body["error_code"] != unprovenRefusalCode || bulkRefusal.Body["is_success"] != int64(0) || bulkRefusal.Body["skills"] != "3|2|1|1|1|1" {
		t.Fatal("MID 39 refusal", bulkRefusal)
	}
	if bulkRefusal.Cause == nil || !strings.Contains(bulkRefusal.Cause.Error(), "hero=9") || !strings.Contains(bulkRefusal.Cause.Error(), "no_change") {
		t.Fatalf("MID 39 refusal must journal the hero and reason: %v", bulkRefusal.Cause)
	}

	stub.bulkErr = apphero.HeroSkillLevelRefusalError{Reason: apphero.HeroSkillLevelRefusalInsufficientPoints, SkillLevels: [6]int64{3, 2, 1, 1, 1, 1}, SkillPoint: 6, SkillTime: 1700000100}
	errorRefusal := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": "2|1", "skill_counts": "1|2"}))
	if errorRefusal.Cause == nil || !strings.Contains(errorRefusal.Cause.Error(), "hero=9") || !strings.Contains(errorRefusal.Cause.Error(), "insufficient_skill_points") {
		t.Fatalf("MID 39 refusal error must journal the hero and reason: %v", errorRefusal.Cause)
	}

	invalid := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": "2|", "skill_counts": "1|2"}))
	if invalid.HTTPStatus != http.StatusBadRequest {
		t.Fatal("invalid MID 39 pipe accepted", invalid)
	}
	if _, present := invalid.Body["skills"]; present {
		t.Fatalf("malformed 400 must stay bodyless: %#v", invalid.Body)
	}
}

func TestHeroSkillLevelMID39EveryNon400RefusalCarriesCommittedFields(t *testing.T) {
	stub := &heroSkillLevelDispatchStub{
		view: apphero.HeroSkillLevelView{SkillLevels: [6]int64{3, 2, 1, 1, 1, 1}, SkillLevelsKnown: true, SkillPoint: 6, SkillPointKnown: true, SkillTime: 1700000100},
	}
	dispatcher := HeroDispatcher{Authority: httpAuthority{actorForHTTP(t)}, Service: &ca23HeroService{}, SkillLevels: stub}
	params := map[string]any{"partner_id": int64(9), "skill_colors": "2|1", "skill_counts": "1|2"}
	for _, tc := range []struct {
		name       string
		err        error
		wantStatus int
		wantCode   int64
	}{
		{"stale time", apphero.ErrHeroSkillLevelStaleTime, http.StatusConflict, staleConflictCode},
		{"inactive content", apphero.ErrHeroSkillLevelInactive, http.StatusConflict, unprovenRefusalCode},
		{"defect", errors.New("boom"), http.StatusInternalServerError, unprovenRefusalCode},
		{"transient", context.DeadlineExceeded, http.StatusServiceUnavailable, serverBusyCode},
	} {
		t.Run(tc.name, func(t *testing.T) {
			stub.bulkErr = tc.err
			heroSkillLevelRefusalFields(t, dispatcher.Dispatch(context.Background(), heroReq(t, 39, params)), tc.wantStatus, tc.wantCode)
		})
	}
	stub.bulkErr = apphero.ErrHeroSkillLevelInactive
	inactive := dispatcher.Dispatch(context.Background(), heroReq(t, 39, params))
	if inactive.Cause == nil || !strings.Contains(inactive.Cause.Error(), "hero=9") || !strings.Contains(inactive.Cause.Error(), "content inactive") {
		t.Fatalf("MID 39 error refusal must journal the hero and cause: %v", inactive.Cause)
	}
	stub.view = apphero.HeroSkillLevelView{SkillPoint: 6, SkillPointKnown: true, SkillTime: 1700000100}
	partial := dispatcher.Dispatch(context.Background(), heroReq(t, 39, params))
	if partial.HTTPStatus != http.StatusConflict || partial.Body["is_success"] != int64(0) || partial.Body["skill_point"] != int64(6) || partial.Body["skill_time"] != int64(1700000100) {
		t.Fatalf("partial read lost its readable fields: %#v", partial.Body)
	}
	if _, present := partial.Body["skills"]; present {
		t.Fatalf("unreadable skills were invented: %#v", partial.Body)
	}
	stub.viewErr = errors.New("read failed")
	unreadable := dispatcher.Dispatch(context.Background(), heroReq(t, 39, params))
	if unreadable.HTTPStatus != http.StatusConflict || unreadable.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("unreadable state changed the error class: %#v", unreadable)
	}
}
