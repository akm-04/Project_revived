package stockruntime

import (
	"context"
	"errors"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	ota "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/mids"
)

// UpdatePlanner is the MID 2 scheduler port.
type UpdatePlanner interface {
	Plan(context.Context, ota.PlanRequest) (ota.UpdatePlan, error)
}

// PreloginDispatcher owns only the stock-client public pre-context HTTP plane.
// These responses carry no account/gameplay authority and perform no mutation.
type PreloginDispatcher struct {
	PublicEngineURL string
	Tracker         *lobby.BootTracker
	Updates         UpdatePlanner
	// ResourceDownloadURL is the MID 20480 lazy-fetch discovery answer; nil or
	// an empty value means lazy fetch is off (I11A_OTA_RELEASE_V1 ruling 6).
	ResourceDownloadURL func(context.Context) (string, error)
}

func (d PreloginDispatcher) Dispatch(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	if d.Tracker != nil {
		_ = d.Tracker.Record(lobby.BootEvent{MID: req.Envelope.MID, Kind: lobby.BootPrelogin, Phase: lobby.PhaseClientRequestObserved, At: req.Envelope.ReceivedAt})
	}
	switch req.Envelope.MID {
	case mids.MIDCenterDiscovery:
		if strings.TrimSpace(d.PublicEngineURL) == "" {
			return failureReply(defect(errors.New("public_engine_url_unconfigured")))
		}
		resourceDownloadURL := ""
		if d.ResourceDownloadURL != nil {
			value, err := d.ResourceDownloadURL(ctx)
			if err != nil {
				return failureFromRows(nil, err)
			}
			resourceDownloadURL = value
		}
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
			"url": d.PublicEngineURL, "server_id": int64(1), "back_domain": "", "res_download_url": resourceDownloadURL,
		}}
	case mids.MIDVersionCheck:
		return d.versionCheck(ctx, req)
	case 7: // LOAD_ANNOUNCE: LoginWindow json-decodes this field.
		return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{"contents": "{\"contents\":[]}"}}
	case 2864: // GET_PLAYER_GROUP_BY_KEY: source consumes a JSON scalar.
		key, _ := req.Envelope.Params["unique_key"].(string)
		return httpedge.Response{HTTPStatus: http.StatusOK, JSON: tutorialGroup(key)}
	default:
		return failureReply(refusal(unprovenRefusalCode))
	}
}

// versionCheck is the MID 2 scheduler reply of I11A_OTA_RELEASE_V1 ruling 4.
// It is the first MID 2 check at each boot, so a database fault must surface
// as a fault rather than as a no-update reply.
func (d PreloginDispatcher) versionCheck(ctx context.Context, req httpedge.DispatchRequest) httpedge.Response {
	noUpdate := httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
		"is_appstore": int64(0), "is_inapp": int64(0), "is_review": int64(0), "need_restart": int64(0),
	}}
	if d.Updates == nil {
		return failureReply(defect(errors.New("ota_version_scheduler_unconfigured")))
	}
	request := ota.PlanRequest{
		ClientVersion: stringParam(req.Envelope.Params, "v"),
		AppVersion:    stringParam(req.Envelope.Params, "app_v"),
	}
	if platform, err := requiredInt64(req.Envelope.Params, "platform"); err == nil {
		request.Platform = platform
	}
	plan, err := d.Updates.Plan(ctx, request)
	if err != nil {
		return failureFromRows(nil, err)
	}
	if plan.UnknownAppVersion && otaAnomalies.shouldLog(request.AppVersion, req.Envelope.ReceivedAt) {
		log.Printf("ANOMALY ota unknown app_v=%q v=%q platform=%d", request.AppVersion, request.ClientVersion, request.Platform)
	}
	if len(plan.Descriptors) == 0 {
		return noUpdate
	}
	descriptors := make([]any, 0, len(plan.Descriptors))
	for _, descriptor := range plan.Descriptors {
		descriptors = append(descriptors, map[string]any{
			"version":  descriptor.Version,
			"volume":   int64(descriptor.Volume),
			"size":     descriptor.Size,
			"md5":      descriptor.MD5,
			"resource": descriptor.Resource,
		})
	}
	isReview := int64(0)
	if plan.IsReview {
		isReview = 1
	}
	return httpedge.Response{HTTPStatus: http.StatusOK, Body: map[string]any{
		"is_appstore": int64(0), "is_inapp": int64(1), "is_review": isReview, "need_restart": int64(0), "res": descriptors,
	}}
}

// tutorialGroup selects the abtest.lua arm that keeps every tutorial on (D111):
// mtspy A shows function-opening weak guides, n7gso B shows newcomer cards.
// Unknown keys keep A, the client's own fallback when the reply is late.
func tutorialGroup(key string) string {
	if strings.EqualFold(strings.TrimSpace(key), "n7gso") {
		return "B"
	}
	return "A"
}

// otaAnomalies keeps the ruling 4 anomaly line to one per app_v per UTC day.
// Its map is reset on the day change and capped so junk app_v values cannot
// grow it without bound.
const maxAnomalyAppVersions = 64

type anomalyLimiter struct {
	mu                sync.Mutex
	day               string
	seen              map[string]struct{}
	suppressionLogged bool
}

var otaAnomalies anomalyLimiter

func (l *anomalyLimiter) shouldLog(appVersion string, at time.Time) bool {
	day := at.UTC().Format("2006-01-02")
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.day != day {
		l.day = day
		l.seen = map[string]struct{}{}
		l.suppressionLogged = false
	}
	if _, logged := l.seen[appVersion]; logged {
		return false
	}
	if len(l.seen) >= maxAnomalyAppVersions {
		if !l.suppressionLogged {
			l.suppressionLogged = true
			log.Printf("ANOMALY ota anomaly log limit reached: %d distinct app_v values today, further lines suppressed", len(l.seen)+1)
		}
		return false
	}
	l.seen[appVersion] = struct{}{}
	return true
}
