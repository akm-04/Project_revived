package operatorapi

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	appota "gxb.local/backend/v2/internal/application/otarelease"
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
