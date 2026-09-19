package stockruntime

import (
	"context"
	"errors"

	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
)

// StaticEndpoints is the I4 single-listener deployment projection. WORLD,
// SERVICE and GUILD remain distinct authenticated physical socket roles even
// when they share one advertised host:port.
type StaticEndpoints struct{ Endpoint apprealtime.Endpoint }

func (s StaticEndpoints) EndpointFor(context.Context, domainrt.PhysicalRole) (apprealtime.Endpoint, error) {
	if s.Endpoint.Host == "" || s.Endpoint.Port <= 0 || s.Endpoint.Port > 65535 {
		return apprealtime.Endpoint{}, errors.New("invalid advertised realtime endpoint")
	}
	return s.Endpoint, nil
}
