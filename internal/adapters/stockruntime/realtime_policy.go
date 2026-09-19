package stockruntime

import (
	"errors"
	"strconv"
	"time"

	"gxb.local/backend/v2/internal/protocol/limits"
)

var ErrRealtimeAdmissionFull = errors.New("realtime admission budget exhausted")
var ErrRealtimeClientIdle = errors.New("realtime client idle timeout")

// RealtimePolicy contains V2 engineering safety budgets. These are explicitly
// configurable operational limits, not recovered original-server constants.
type RealtimePolicy struct {
	MaxConnections       int
	MaxPreauth           int
	MaxEstablished       int
	HandshakeTimeout     time.Duration
	AuthQueryTimeout     time.Duration
	LivenessQueryTimeout time.Duration
	LivenessInterval     time.Duration
	ClientIdleTimeout    time.Duration
	WriteTimeout         time.Duration
	heartbeatInterval    time.Duration // source constant; overridable only by package tests
}

func DefaultRealtimePolicy() RealtimePolicy {
	return RealtimePolicy{
		MaxConnections:       2048,
		MaxPreauth:           256,
		MaxEstablished:       2048,
		HandshakeTimeout:     limits.StockTCPLoginTimeout,
		AuthQueryTimeout:     3 * time.Second,
		LivenessQueryTimeout: 3 * time.Second,
		LivenessInterval:     30 * time.Second,
		ClientIdleTimeout:    2*limits.StockHeartbeatInterval + 30*time.Second,
		WriteTimeout:         5 * time.Second,
		heartbeatInterval:    limits.StockHeartbeatInterval,
	}
}

func (p RealtimePolicy) Validate() error {
	if p.MaxConnections <= 0 || p.MaxPreauth <= 0 || p.MaxEstablished <= 0 {
		return errors.New("realtime admission limits must be positive")
	}
	if p.MaxPreauth > p.MaxConnections || p.MaxEstablished > p.MaxConnections {
		return errors.New("realtime role admission limit exceeds total connections")
	}
	if p.HandshakeTimeout <= 0 || p.AuthQueryTimeout <= 0 || p.LivenessQueryTimeout <= 0 || p.LivenessInterval <= 0 || p.ClientIdleTimeout <= 0 || p.WriteTimeout <= 0 {
		return errors.New("realtime time budgets must be positive")
	}
	hb := p.heartbeatInterval
	if hb <= 0 {
		hb = limits.StockHeartbeatInterval
	}
	if p.ClientIdleTimeout <= hb {
		return errors.New("client idle timeout must exceed stock heartbeat interval")
	}
	return nil
}

// RealtimePolicyFromEnv applies optional duration/integer overrides. Getter is
// injected so parsing is deterministic and unit-testable. Durations use Go
// duration syntax, e.g. "3s" or "21m".
func RealtimePolicyFromEnv(getenv func(string) string) (RealtimePolicy, error) {
	p := DefaultRealtimePolicy()
	if getenv == nil {
		return p, p.Validate()
	}
	ints := []struct {
		name string
		dst  *int
	}{{"GXB_REALTIME_MAX_CONNECTIONS", &p.MaxConnections}, {"GXB_REALTIME_MAX_PREAUTH", &p.MaxPreauth}, {"GXB_REALTIME_MAX_ESTABLISHED", &p.MaxEstablished}}
	for _, x := range ints {
		if v := getenv(x.name); v != "" {
			n, err := strconv.Atoi(v)
			if err != nil {
				return RealtimePolicy{}, err
			}
			*x.dst = n
		}
	}
	durations := []struct {
		name string
		dst  *time.Duration
	}{
		{"GXB_REALTIME_HANDSHAKE_TIMEOUT", &p.HandshakeTimeout},
		{"GXB_REALTIME_AUTH_QUERY_TIMEOUT", &p.AuthQueryTimeout},
		{"GXB_REALTIME_LIVENESS_QUERY_TIMEOUT", &p.LivenessQueryTimeout},
		{"GXB_REALTIME_LIVENESS_INTERVAL", &p.LivenessInterval},
		{"GXB_REALTIME_CLIENT_IDLE_TIMEOUT", &p.ClientIdleTimeout},
		{"GXB_REALTIME_WRITE_TIMEOUT", &p.WriteTimeout},
	}
	for _, x := range durations {
		if v := getenv(x.name); v != "" {
			d, err := time.ParseDuration(v)
			if err != nil {
				return RealtimePolicy{}, err
			}
			*x.dst = d
		}
	}
	return p, p.Validate()
}

type admissionLease struct {
	lim         *AdmissionLimiter
	preauth     bool
	established bool
	released    bool
}

// AdmissionLimiter bounds total, pre-authenticated and established sockets for
// one runtime process. Multi-process ownership remains EX-05.
type AdmissionLimiter struct {
	total       chan struct{}
	preauth     chan struct{}
	established chan struct{}
}

func NewAdmissionLimiter(p RealtimePolicy) (*AdmissionLimiter, error) {
	if err := p.Validate(); err != nil {
		return nil, err
	}
	return &AdmissionLimiter{total: make(chan struct{}, p.MaxConnections), preauth: make(chan struct{}, p.MaxPreauth), established: make(chan struct{}, p.MaxEstablished)}, nil
}

func tryTake(ch chan struct{}) bool {
	select {
	case ch <- struct{}{}:
		return true
	default:
		return false
	}
}
func give(ch chan struct{}) { <-ch }

func (l *AdmissionLimiter) AcquirePreauth() (*admissionLease, error) {
	if l == nil {
		return &admissionLease{}, nil
	}
	if !tryTake(l.total) {
		return nil, ErrRealtimeAdmissionFull
	}
	if !tryTake(l.preauth) {
		give(l.total)
		return nil, ErrRealtimeAdmissionFull
	}
	return &admissionLease{lim: l, preauth: true}, nil
}

func (x *admissionLease) Promote() error {
	if x == nil || x.lim == nil {
		return nil
	}
	if x.established {
		return nil
	}
	if !tryTake(x.lim.established) {
		return ErrRealtimeAdmissionFull
	}
	x.established = true
	if x.preauth {
		give(x.lim.preauth)
		x.preauth = false
	}
	return nil
}

func (x *admissionLease) Release() {
	if x == nil || x.released || x.lim == nil {
		return
	}
	x.released = true
	if x.preauth {
		give(x.lim.preauth)
	}
	if x.established {
		give(x.lim.established)
	}
	give(x.lim.total)
}
