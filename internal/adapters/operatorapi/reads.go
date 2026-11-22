package operatorapi

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"time"

	appevents "gxb.local/backend/v2/internal/application/events"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	apppublication "gxb.local/backend/v2/internal/application/publication"
	"gxb.local/backend/v2/internal/domain/events"
)

// OTAStatusService is the ota.status read.
type OTAStatusService interface {
	Status(context.Context) (appota.Status, error)
}

// OTAStatus adapts ota.status to the read registry.
func OTAStatus(service OTAStatusService) Read {
	return func(ctx context.Context, _ url.Values) (any, error) {
		return service.Status(ctx)
	}
}

// OTAReleaseService is the ota.release read.
type OTAReleaseService interface {
	Exists(context.Context, string) (appota.ReleaseExistence, error)
}

// OTARelease adapts ota.release to the read registry: it answers whether a
// release number exists in any state (L4f fix 2).
func OTARelease(service OTAReleaseService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		version := values.Get("version")
		if version == "" {
			return nil, operator.Refuse(operator.CodeReadInvalid, "version is required", nil)
		}
		return service.Exists(ctx, version)
	}
}

// ServerListService is the server.list read.
type ServerListService interface {
	List(context.Context) (operator.ServerListPage, error)
}

// ServerList adapts server.list to the read registry.
func ServerList(service ServerListService) Read {
	return func(ctx context.Context, _ url.Values) (any, error) {
		return service.List(ctx)
	}
}

// SessionOnlineService is the session.online read.
type SessionOnlineService interface {
	Online(context.Context, operator.OnlineSessionFilter) (operator.OnlineSessionPage, error)
}

// SessionOnline adapts session.online to the read registry.
func SessionOnline(service SessionOnlineService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		filter := operator.OnlineSessionFilter{After: values.Get("after")}
		if rawServer := values.Get("server_id"); rawServer != "" {
			server, err := strconv.ParseInt(rawServer, 10, 64)
			if err != nil || server <= 0 {
				return nil, operator.Refuse(operator.CodeReadInvalid, "server_id must be a positive id", nil)
			}
			filter.ServerID = &server
		}
		if rawLimit := values.Get("limit"); rawLimit != "" {
			limit, err := strconv.Atoi(rawLimit)
			if err != nil {
				return nil, operator.Refuse(operator.CodeReadInvalid, "limit must be a number", nil)
			}
			filter.Limit = limit
		}
		return service.Online(ctx, filter)
	}
}

// PublicationShowService is the publication.show read.
type PublicationShowService interface {
	Show(context.Context, string, int64) (apppublication.ShowReply, error)
}

// PublicationShow adapts publication.show to the read registry.
func PublicationShow(service PublicationShowService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		var serverID int64
		if rawServer := values.Get("server_id"); rawServer != "" {
			parsed, err := strconv.ParseInt(rawServer, 10, 64)
			if err != nil || parsed < 0 {
				return nil, operator.Refuse(operator.CodeReadInvalid, "server_id must be zero or positive", nil)
			}
			serverID = parsed
		}
		return service.Show(ctx, values.Get("family"), serverID)
	}
}

// AuditListService is the operator.audit.list read.
type AuditListService interface {
	List(context.Context, operator.AuditFilter) (operator.AuditPage, error)
}

// AuditList adapts operator.audit.list to the read registry.
func AuditList(service AuditListService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		filter, err := parseAuditFilter(values)
		if err != nil {
			return nil, err
		}
		return service.List(ctx, filter)
	}
}

func parseAuditFilter(values url.Values) (operator.AuditFilter, error) {
	var filter operator.AuditFilter
	filter.Module = values.Get("module")
	filter.Principal = values.Get("principal")
	filter.SemanticKey = values.Get("semantic_key")
	from, err := parseAuditTime("from", values.Get("from"))
	if err != nil {
		return operator.AuditFilter{}, err
	}
	to, err := parseAuditTime("to", values.Get("to"))
	if err != nil {
		return operator.AuditFilter{}, err
	}
	filter.From, filter.To = from, to
	if rawLimit := values.Get("limit"); rawLimit != "" {
		limit, err := strconv.Atoi(rawLimit)
		if err != nil {
			return operator.AuditFilter{}, operator.Refuse(operator.CodeReadInvalid, "limit must be a number", nil)
		}
		filter.Limit = limit
	}
	if rawCursor := values.Get("cursor"); rawCursor != "" {
		cursor, err := operator.ParseAuditCursor(rawCursor)
		if err != nil {
			return operator.AuditFilter{}, err
		}
		filter.Cursor = cursor
	}
	return filter, nil
}

func parseAuditTime(name, text string) (*time.Time, error) {
	if text == "" {
		return nil, nil
	}
	parsed, err := time.Parse(time.RFC3339, text)
	if err != nil {
		return nil, operator.Refuse(operator.CodeReadInvalid, fmt.Sprintf("%s must be RFC3339: %v", name, err), nil)
	}
	return &parsed, nil
}

// EventsListService is the events.list read.
type EventsListService interface {
	List(context.Context, appevents.OccurrenceFilter) (appevents.OccurrencePage, error)
}

// EventsList adapts events.list to the read registry (I11A_EVENTS_V1 ruling 11).
func EventsList(service EventsListService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		filter, err := parseEventsFilter(values)
		if err != nil {
			return nil, err
		}
		return service.List(ctx, filter)
	}
}

// RedeemListService is the redeem.list read.
type RedeemListService interface {
	List(context.Context, string, int) (appi5.RedeemPage, error)
}

// RedeemList adapts redeem.list to the read registry (bounded to 200 rows).
func RedeemList(service RedeemListService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		limit := 0
		if rawLimit := values.Get("limit"); rawLimit != "" {
			parsed, err := strconv.Atoi(rawLimit)
			if err != nil || parsed < 1 || parsed > appi5.MaxRedeemListLimit {
				return nil, operator.Refuse(operator.CodeReadInvalid, fmt.Sprintf("limit must be between 1 and %d", appi5.MaxRedeemListLimit), nil)
			}
			limit = parsed
		}
		return service.List(ctx, values.Get("after"), limit)
	}
}

// CatalogSearch adapts catalog.search to the shared operator catalogue
// (I11A_OPERATOR_COMMANDS_V1 ruling 9).
func CatalogSearch(document operatorcatalog.Document) Read {
	return func(_ context.Context, values url.Values) (any, error) {
		filter := operatorcatalog.SearchFilter{Kind: values.Get("kind"), Query: values.Get("query"), After: values.Get("after")}
		if rawLimit := values.Get("limit"); rawLimit != "" {
			limit, err := strconv.Atoi(rawLimit)
			if err != nil || limit < 1 || limit > operatorcatalog.MaxSearchLimit {
				return nil, operator.Refuse(operator.CodeReadInvalid, fmt.Sprintf("limit must be between 1 and %d", operatorcatalog.MaxSearchLimit), nil)
			}
			filter.Limit = limit
		}
		page, err := document.Search(filter)
		if err != nil {
			return nil, operator.Refuse(operator.CodeReadInvalid, err.Error(), nil)
		}
		return page, nil
	}
}

// BulkShowService is the operator.bulk.show read.
type BulkShowService interface {
	Show(context.Context, string) (operatorgrant.BulkProgress, error)
}

// BulkShow adapts operator.bulk.show to the read registry.
func BulkShow(service BulkShowService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		semanticKey := values.Get("semantic_key")
		if semanticKey == "" {
			return nil, operator.Refuse(operator.CodeReadInvalid, "semantic_key is required", nil)
		}
		return service.Show(ctx, semanticKey)
	}
}

// PlayerFindService is the player.find read.
type PlayerFindService interface {
	Find(context.Context, playerdirectory.OperatorFind) (operator.PlayerFindPage, error)
}

// PlayerFind adapts player.find to the read registry.
func PlayerFind(service PlayerFindService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		filter := playerdirectory.OperatorFind{UID: values.Get("uid"), NamePrefix: values.Get("name_prefix")}
		if rawServer := values.Get("server_id"); rawServer != "" {
			server, err := strconv.ParseInt(rawServer, 10, 64)
			if err != nil || server <= 0 {
				return nil, operator.Refuse(operator.CodeReadInvalid, "server_id must be a positive id", nil)
			}
			filter.ServerID = &server
		}
		if rawLimit := values.Get("limit"); rawLimit != "" {
			limit, err := strconv.Atoi(rawLimit)
			if err != nil {
				return nil, operator.Refuse(operator.CodeReadInvalid, "limit must be a number", nil)
			}
			filter.Limit = limit
		}
		return service.Find(ctx, filter)
	}
}

// PlayerSummaryService is the player.summary read.
type PlayerSummaryService interface {
	Summary(context.Context, int64) (operator.PlayerSummary, error)
}

// PlayerSummary adapts player.summary to the read registry.
func PlayerSummary(service PlayerSummaryService) Read {
	return func(ctx context.Context, values url.Values) (any, error) {
		playerID, err := strconv.ParseInt(values.Get("player_id"), 10, 64)
		if err != nil || playerID <= 0 {
			return nil, operator.Refuse(operator.CodeReadInvalid, "player_id must be a positive id", nil)
		}
		return service.Summary(ctx, playerID)
	}
}

func parseEventsFilter(values url.Values) (appevents.OccurrenceFilter, error) {
	var filter appevents.OccurrenceFilter
	server, err := strconv.ParseInt(values.Get("server"), 10, 64)
	if err != nil || server <= 0 {
		return appevents.OccurrenceFilter{}, operator.Refuse(operator.CodeReadInvalid, "server must be a positive logical server id", nil)
	}
	filter.LogicalServerID = server
	if rawState := values.Get("state"); rawState != "" {
		phase := events.Phase(rawState)
		switch phase {
		case events.PhaseScheduled, events.PhaseRunning, events.PhaseClaimWindow, events.PhaseEnded, events.PhaseArchived, events.PhaseCancelled:
			filter.Phase = &phase
		default:
			return appevents.OccurrenceFilter{}, operator.Refuse(operator.CodeReadInvalid, "state is not an event lifecycle state", nil)
		}
	}
	from, err := parseAuditTime("from", values.Get("from"))
	if err != nil {
		return appevents.OccurrenceFilter{}, err
	}
	to, err := parseAuditTime("to", values.Get("to"))
	if err != nil {
		return appevents.OccurrenceFilter{}, err
	}
	filter.From, filter.To = from, to
	if rawLimit := values.Get("limit"); rawLimit != "" {
		limit, err := strconv.Atoi(rawLimit)
		if err != nil {
			return appevents.OccurrenceFilter{}, operator.Refuse(operator.CodeReadInvalid, "limit must be a number", nil)
		}
		if limit < 1 || limit > appevents.MaxListLimit {
			return appevents.OccurrenceFilter{}, operator.Refuse(operator.CodeReadInvalid, fmt.Sprintf("limit must be between 1 and %d", appevents.MaxListLimit), nil)
		}
		filter.Limit = limit
	}
	if rawCursor := values.Get("cursor"); rawCursor != "" {
		cursor, err := appevents.ParseOccurrenceCursor(rawCursor)
		if err != nil {
			return appevents.OccurrenceFilter{}, operator.Refuse(operator.CodeReadInvalid, err.Error(), nil)
		}
		filter.Cursor = cursor
	}
	return filter, nil
}
