package stockruntime

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"
	"testing"
	"time"

	ota "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func mid2Request(at time.Time, clientVersion, appVersion string) httpedge.DispatchRequest {
	return httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{
		MID: 2, ReceivedAt: at,
		Params: map[string]any{"v": clientVersion, "app_v": appVersion, "platform": int64(3)},
	}}
}

func TestPreloginMID2EncodesDescriptorReply(t *testing.T) {
	const resource = "https://engine.example/updates/assets/1.631.1-aaaaaaaaaaaa.zip"
	planner := fakeUpdatePlanner{plan: ota.UpdatePlan{
		Descriptors: []ota.Descriptor{{
			Version: "1.631.1", Volume: 2, Size: 3000, MD5: "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", Resource: resource,
		}},
		IsReview: true,
	}}
	response := PreloginDispatcher{Updates: planner}.Dispatch(context.Background(), mid2Request(time.Unix(1, 0), "1.631.0", ota.StockAppVersion))
	if response.HTTPStatus != http.StatusOK || response.Body["is_inapp"] != int64(1) || response.Body["is_review"] != int64(1) || response.Body["need_restart"] != int64(0) {
		t.Fatalf("response=%+v", response)
	}
	rows, ok := response.Body["res"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("res=%#v", response.Body["res"])
	}
	descriptor, ok := rows[0].(map[string]any)
	if !ok {
		t.Fatalf("descriptor=%#v", rows[0])
	}
	if descriptor["version"] != "1.631.1" || descriptor["volume"] != int64(2) || descriptor["size"] != int64(3000) || descriptor["md5"] != "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" || descriptor["resource"] != resource {
		t.Fatalf("descriptor=%+v", descriptor)
	}
	replyconformance.Check(t, 2, response.Body)
}

func TestPreloginMID2DatabaseFaultIsNotNoUpdate(t *testing.T) {
	response := PreloginDispatcher{Updates: fakeUpdatePlanner{err: context.DeadlineExceeded}}.Dispatch(context.Background(), mid2Request(time.Unix(1, 0), "1.631.0", ota.StockAppVersion))
	if response.HTTPStatus != http.StatusServiceUnavailable || response.Body["error_code"] != serverBusyCode {
		t.Fatalf("response=%+v", response)
	}
	if _, present := response.Body["is_inapp"]; present {
		t.Fatalf("fault reply looks like a no-update reply: %+v", response.Body)
	}
}

func TestPreloginMID2InvalidReleaseIsDefect(t *testing.T) {
	response := PreloginDispatcher{Updates: fakeUpdatePlanner{err: ota.ErrInvalidRelease}}.Dispatch(context.Background(), mid2Request(time.Unix(1, 0), "1.631.0", ota.StockAppVersion))
	if response.HTTPStatus != http.StatusInternalServerError || response.Body["error_code"] != unprovenRefusalCode {
		t.Fatalf("response=%+v", response)
	}
}

func TestPreloginMID2AnomalyLimiterLogsOneSuppressionLine(t *testing.T) {
	otaAnomalies = anomalyLimiter{}
	defer func() { otaAnomalies = anomalyLimiter{} }()
	var output bytes.Buffer
	previous := log.Writer()
	log.SetOutput(&output)
	defer log.SetOutput(previous)

	dispatcher := PreloginDispatcher{Updates: fakeUpdatePlanner{plan: ota.UpdatePlan{UnknownAppVersion: true}}}
	at := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	for index := 0; index <= maxAnomalyAppVersions; index++ {
		dispatcher.Dispatch(context.Background(), mid2Request(at, "1.631.0", fmt.Sprintf("1.630.%d", index)))
	}
	logged := output.String()
	if got := strings.Count(logged, "unknown app_v="); got != maxAnomalyAppVersions {
		t.Fatalf("individual lines=%d want %d:\n%s", got, maxAnomalyAppVersions, logged)
	}
	if got := strings.Count(logged, "anomaly log limit reached"); got != 1 {
		t.Fatalf("suppression lines=%d want 1:\n%s", got, logged)
	}
	if !strings.Contains(logged, "65 distinct app_v values") {
		t.Fatalf("suppression line missing the count:\n%s", logged)
	}
}
