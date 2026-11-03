//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/course"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func courseDispatch(t *testing.T, actor identity.ActorContext, service stockruntime.CoursePort, mid uint16, params map[string]any, operationContext operation.Context) httpedge.Response {
	t.Helper()
	dispatcher := stockruntime.CourseDispatcher{Authority: fixedLibraryAuthority{actor: actor}, Service: service}
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{MID: mid, Operation: operationContext, ReceivedAt: time.Now().UTC(),
		Claims: wire.CredentialClaims{Token: "fixture", Region: int64(actor.LogicalServerID)}, Params: params}})
}

func courseGiftBoxReceiptBody(t *testing.T, p *pg.Pool, player identity.PlayerID, operationContext operation.Context) map[string]any {
	t.Helper()
	var payload string
	e := p.QueryRow(ctx, `SELECT result_payload::text FROM gxb_operation_receipts WHERE owner_kind='player' AND owner_key=$1 AND domain='course' AND operation=$2 AND semantic_key=$3`, strconv.FormatInt(int64(player), 10), app.GiftBox, operationContext.ID.String()).Scan(&payload)
	if e != nil {
		t.Fatal(e)
	}
	var stored struct {
		Body map[string]any
	}
	if e = json.Unmarshal([]byte(payload), &stored); e != nil {
		t.Fatal(e)
	}
	return stored.Body
}

func courseGiftBoxStackCount(t *testing.T, p *pg.Pool, player identity.PlayerID, itemID int64) int64 {
	t.Helper()
	var count int64
	if e := p.QueryRow(ctx, `SELECT COALESCE(max(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(player), itemID).Scan(&count); e != nil {
		t.Fatal(e)
	}
	return count
}

func courseGiftBoxAward(t *testing.T, body map[string]any) map[string]any {
	t.Helper()
	awards, ok := body["awards"].([]any)
	if !ok || len(awards) != 1 {
		t.Fatalf("awards %T %+v", body["awards"], body["awards"])
	}
	row, ok := awards[0].(map[string]any)
	if !ok {
		t.Fatalf("award row %T", awards[0])
	}
	return row
}

func TestI9_10B2141GiftBoxDailyFlagAndPurchased(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	service := courseService(p, p)

	response := courseDispatch(t, a, service, 2139, map[string]any{}, op())
	if response.HTTPStatus != 200 || response.Body["is_has_gift"] != int64(1) {
		t.Fatalf("2139 before status %d body %+v", response.HTTPStatus, response.Body)
	}

	dailyOperation := op()
	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.DailyGiftBoxItemID}, dailyOperation)
	if response.HTTPStatus != 200 || response.Body["is_has_gift"] != int64(0) {
		t.Fatalf("2141 daily status %d body %+v", response.HTTPStatus, response.Body)
	}
	dailyAward := courseGiftBoxAward(t, response.Body)
	dailyItem, ok := dailyAward["table_id"].(int64)
	if !ok || dailyItem < 50001420 || dailyItem > 50001422 || dailyAward["item_num"] != int64(1) {
		t.Fatalf("daily award %+v", dailyAward)
	}
	if got := courseGiftBoxStackCount(t, p, a.PlayerID, course.DailyGiftBoxItemID); got != 0 {
		t.Fatalf("daily box debited %d", got)
	}
	root, e := (coursestore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.GiftBoxDay != modes.Day(time.Now().UTC()) {
		t.Fatalf("gift box day %+v %v", root, e)
	}
	receiptBody := courseGiftBoxReceiptBody(t, p, a.PlayerID, dailyOperation)
	if receiptBody["is_has_gift"] != float64(0) {
		t.Fatalf("receipt body %+v", receiptBody)
	}
	if awards, ok := receiptBody["awards"].([]any); !ok || len(awards) != 1 {
		t.Fatalf("receipt awards %T %+v", receiptBody["awards"], receiptBody["awards"])
	}

	response = courseDispatch(t, a, service, 2139, map[string]any{}, op())
	if response.HTTPStatus != 200 || response.Body["is_has_gift"] != int64(0) {
		t.Fatalf("2139 after daily status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.DailyGiftBoxItemID}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("daily without item status %d body %+v", response.HTTPStatus, response.Body)
	}

	seedStack(t, p, a, rev, course.DailyGiftBoxItemID, 2)
	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.DailyGiftBoxItemID}, op())
	if response.HTTPStatus != 200 || response.Body["is_has_gift"] != int64(0) {
		t.Fatalf("daily from item status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := courseGiftBoxStackCount(t, p, a.PlayerID, course.DailyGiftBoxItemID); got != 1 {
		t.Fatalf("daily item stack %d", got)
	}

	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.PurchasedGiftBoxItemID}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("purchased without item status %d body %+v", response.HTTPStatus, response.Body)
	}
	seedStack(t, p, a, rev, course.PurchasedGiftBoxItemID, 1)
	purchasedOperation := op()
	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.PurchasedGiftBoxItemID}, purchasedOperation)
	if response.HTTPStatus != 200 || response.Body["is_has_gift"] != int64(0) {
		t.Fatalf("purchased status %d body %+v", response.HTTPStatus, response.Body)
	}
	purchasedAward := courseGiftBoxAward(t, response.Body)
	purchasedItem, ok := purchasedAward["table_id"].(int64)
	if !ok || purchasedItem < 50001421 || purchasedItem > 50001423 || purchasedAward["item_num"] != int64(1) {
		t.Fatalf("purchased award %+v", purchasedAward)
	}
	if got := courseGiftBoxStackCount(t, p, a.PlayerID, course.PurchasedGiftBoxItemID); got != 0 {
		t.Fatalf("purchased stack %d", got)
	}
	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.PurchasedGiftBoxItemID}, purchasedOperation)
	if response.HTTPStatus != 200 || courseGiftBoxAward(t, response.Body)["table_id"] != float64(purchasedItem) {
		t.Fatalf("purchased replay status %d body %+v", response.HTTPStatus, response.Body)
	}
	if got := courseGiftBoxStackCount(t, p, a.PlayerID, course.PurchasedGiftBoxItemID); got != 0 {
		t.Fatalf("purchased replay stack %d", got)
	}

	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": int64(50001417)}, op())
	if response.HTTPStatus != 409 || response.Body["error_code"] != int64(1) {
		t.Fatalf("unknown box status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = courseDispatch(t, a, service, 2141, map[string]any{}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("missing item status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = courseDispatch(t, a, service, 2141, map[string]any{"item_id": course.DailyGiftBoxItemID, "partner_id": int64(1)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("partner param status %d body %+v", response.HTTPStatus, response.Body)
	}

	exec(t, p, `UPDATE player_course_roots SET gift_box_day=gift_box_day-1 WHERE player_id=$1`, int64(a.PlayerID))
	response = courseDispatch(t, a, service, 2139, map[string]any{}, op())
	if response.HTTPStatus != 200 || response.Body["is_has_gift"] != int64(1) {
		t.Fatalf("2139 next day status %d body %+v", response.HTTPStatus, response.Body)
	}
}

func TestI9_10B2500RecommendListPresent(t *testing.T) {
	p := pool(t)
	a := bornActor(t, p)
	service := courseService(p, p)

	response := courseDispatch(t, a, service, 2500, map[string]any{"table_id": int64(10001001)}, op())
	if response.HTTPStatus != 200 {
		t.Fatalf("2500 status %d body %+v", response.HTTPStatus, response.Body)
	}
	recommendList, ok := response.Body["recommend_list"].([]any)
	if !ok || len(recommendList) != 0 {
		t.Fatalf("recommend_list %T %+v", response.Body["recommend_list"], response.Body["recommend_list"])
	}
	response = courseDispatch(t, a, service, 2500, map[string]any{}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("2500 missing table status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = courseDispatch(t, a, service, 2500, map[string]any{"table_id": int64(0)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("2500 zero table status %d body %+v", response.HTTPStatus, response.Body)
	}
	response = courseDispatch(t, a, service, 2500, map[string]any{"table_id": int64(10001001), "partner_id": int64(1)}, op())
	if response.HTTPStatus != 400 {
		t.Fatalf("2500 extra param status %d body %+v", response.HTTPStatus, response.Body)
	}
}
