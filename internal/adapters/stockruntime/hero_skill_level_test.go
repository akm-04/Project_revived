package stockruntime

import (
	"context"
	"net/http"
	"reflect"
	"testing"

	apphero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type heroSkillLevelDispatchStub struct {
	singleResult  apphero.HeroSkillLevelResult
	bulkResult    apphero.HeroSkillLevelResult
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
	return stub.bulkResult, nil
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

	stub.singleResult.Success = false
	singleRefusal := dispatcher.Dispatch(context.Background(), heroReq(t, 53, map[string]any{"partner_id": int64(7), "skill_index": int64(2)}))
	if singleRefusal.HTTPStatus != http.StatusConflict || singleRefusal.Body["error_code"] != unprovenRefusalCode || singleRefusal.Body["skill_point"] != int64(8) {
		t.Fatal("MID 53 refusal", singleRefusal)
	}

	stub.bulkResult.Success = false
	bulkRefusal := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": "2|1", "skill_counts": "1|2"}))
	if bulkRefusal.HTTPStatus != http.StatusConflict || bulkRefusal.Body["error_code"] != unprovenRefusalCode || bulkRefusal.Body["is_success"] != int64(0) || bulkRefusal.Body["skills"] != "3|2|1|1|1|1" {
		t.Fatal("MID 39 refusal", bulkRefusal)
	}

	invalid := dispatcher.Dispatch(context.Background(), heroReq(t, 39, map[string]any{"partner_id": int64(9), "skill_colors": "2|", "skill_counts": "1|2"}))
	if invalid.HTTPStatus != http.StatusBadRequest {
		t.Fatal("invalid MID 39 pipe accepted", invalid)
	}
}
