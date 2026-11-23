package operatoragent

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	// PingSampleLimit keeps one hour at the ten-second interval (G37).
	PingSampleLimit = 360
	// PingInterval is the sampler tick.
	PingInterval = 10 * time.Second
	// PingTimeout bounds one local or internet TCP probe.
	PingTimeout = 2 * time.Second
	// PingPublicTimeout bounds one HTTP probe of a public URL.
	PingPublicTimeout = 5 * time.Second

	pingInternetID     = "internet"
	pingBackendAPIID   = "backend_api"
	pingOperatorID     = "backend_operator"
	pingRealtimeID     = "backend_realtime"
	pingPublicURLID    = "public_backend"
	pingAssetServerID  = "asset_server"
	pingHTTPAddressKey = "GXB_HTTP_ADDR"
	pingRealtimeKey    = "GXB_REALTIME_ADDR"
)

// PingSample is one probe result; Milliseconds is null when the probe failed
// and Error says why.
type PingSample struct {
	At           time.Time `json:"at"`
	Milliseconds *int64    `json:"ms"`
	Error        string    `json:"error,omitempty"`
}

// PingTarget is one probed address with its retained history, oldest first.
type PingTarget struct {
	ID      string       `json:"id"`
	Label   string       `json:"label"`
	Address string       `json:"address"`
	Samples []PingSample `json:"samples"`
}

// PingOmission names a target the plan cannot probe because its address is
// unknown; it is omitted rather than guessed.
type PingOmission struct {
	ID     string `json:"id"`
	Reason string `json:"reason"`
}

// PingReport is the dashboard.pings reply.
type PingReport struct {
	Targets []PingTarget   `json:"targets"`
	Omitted []PingOmission `json:"omitted,omitempty"`
}

// PingTargetSpec is one resolved probe. Probe returns nil when the address
// answered; the sampler times it.
type PingTargetSpec struct {
	ID      string
	Label   string
	Address string
	Timeout time.Duration
	Probe   func(context.Context) error
}

// PingPlan resolves the targets from the agent configuration and the two
// places the client-facing URL can come from.
type PingPlan struct {
	Config Config
	// ServerURL answers the client-facing URL and its source, or empty when
	// unknown.
	ServerURL func() (string, string)
	// Environment reads the agent process environment; nil means os.Getenv.
	Environment func(string) string
}

// Specs resolves the targets and the omissions for the current configuration.
func (plan PingPlan) Specs() ([]PingTargetSpec, []PingOmission) {
	specs := []PingTargetSpec{
		tcpPingTarget(pingInternetID, "Internet (TCP connect time)", "1.1.1.1:443", PingTimeout),
	}
	omissions := []PingOmission{}
	addLocalPort := func(id, label, address, key string) {
		if address == "" {
			omissions = append(omissions, PingOmission{ID: id, Reason: key + " is not set in the backend env file or the agent environment"})
			return
		}
		local, err := loopbackEndpoint(address)
		if err != nil {
			omissions = append(omissions, PingOmission{ID: id, Reason: key + " " + strconv.Quote(address) + " has no port"})
			return
		}
		specs = append(specs, tcpPingTarget(id, label, local, PingTimeout))
	}
	addLocalPort(pingOperatorID, "Backend operator port (TCP connect time)", plan.Config.Backend.OperatorAddr, "backend.operator_addr")
	addLocalPort(pingBackendAPIID, "Backend API (TCP connect time)", plan.setting(pingHTTPAddressKey), pingHTTPAddressKey)
	addLocalPort(pingRealtimeID, "Realtime server (TCP connect time)", plan.setting(pingRealtimeKey), pingRealtimeKey)

	serverURL := ""
	if plan.ServerURL != nil {
		serverURL, _ = plan.ServerURL()
	}
	serverURL = strings.TrimRight(strings.TrimSpace(serverURL), "/")
	if serverURL == "" {
		omissions = append(omissions,
			PingOmission{ID: pingPublicURLID, Reason: "the server URL is not set in the backend env file or the agent environment"},
			PingOmission{ID: pingAssetServerID, Reason: "the client downloads assets from the server URL (/res/), which is not set"},
		)
		return specs, omissions
	}
	specs = append(specs,
		httpPingTarget(pingPublicURLID, "Backend through the internet (HTTP)", serverURL, PingPublicTimeout),
		httpPingTarget(pingAssetServerID, "Asset server (HTTP)", serverURL+"/res/", PingPublicTimeout),
	)
	return specs, omissions
}

// setting reads one backend setting in the backend's own precedence: the env
// file entry first, then the agent's process environment.
func (plan PingPlan) setting(key string) string {
	fromFile, err := ReadEnvValue(plan.Config.Backend.EnvFile, key)
	if err == nil && fromFile != "" {
		return fromFile
	}
	if plan.Environment != nil {
		return plan.Environment(key)
	}
	return os.Getenv(key)
}

func tcpPingTarget(id, label, address string, timeout time.Duration) PingTargetSpec {
	return PingTargetSpec{
		ID:      id,
		Label:   label,
		Address: address,
		Timeout: timeout,
		Probe: func(ctx context.Context) error {
			dialer := net.Dialer{Timeout: timeout}
			connection, err := dialer.DialContext(ctx, "tcp", address)
			if err != nil {
				return err
			}
			return connection.Close()
		},
	}
}

func httpPingTarget(id, label, address string, timeout time.Duration) PingTargetSpec {
	return PingTargetSpec{
		ID:      id,
		Label:   label,
		Address: address,
		Timeout: timeout,
		Probe: func(ctx context.Context) error {
			request, err := http.NewRequestWithContext(ctx, http.MethodGet, address, nil)
			if err != nil {
				return err
			}
			client := &http.Client{Timeout: timeout}
			response, err := client.Do(request)
			if err != nil {
				return err
			}
			_ = response.Body.Close()
			return nil
		},
	}
}

// loopbackEndpoint keeps only the port of a configured listen address and
// probes it on the loopback interface.
func loopbackEndpoint(address string) (string, error) {
	_, port, err := net.SplitHostPort(strings.TrimSpace(address))
	if err != nil || port == "" {
		return "", fmt.Errorf("%s has no port", address)
	}
	return net.JoinHostPort("127.0.0.1", port), nil
}

// PingSampler keeps the recent probe history in memory and answers the
// dashboard.pings read.
//
// shortcut: history is in memory and resets when the agent restarts; persist it
// only if the owner asks.
type PingSampler struct {
	Specs    func() ([]PingTargetSpec, []PingOmission)
	Interval time.Duration
	Now      func() time.Time

	mutex   sync.Mutex
	history map[string][]PingSample
}

// NewPingSampler builds the sampler for one plan.
func NewPingSampler(plan PingPlan, now func() time.Time) *PingSampler {
	if now == nil {
		now = time.Now
	}
	return &PingSampler{Specs: plan.Specs, Interval: PingInterval, Now: now, history: map[string][]PingSample{}}
}

// Run samples once and then on every tick until the agent context ends.
func (sampler *PingSampler) Run(ctx context.Context) {
	interval := sampler.Interval
	if interval <= 0 {
		interval = PingInterval
	}
	sampler.SampleOnce(ctx)
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			sampler.SampleOnce(ctx)
		}
	}
}

// SampleOnce probes every target in parallel, so one slow target never delays
// the others past the tick.
func (sampler *PingSampler) SampleOnce(ctx context.Context) {
	specs, _ := sampler.Specs()
	var group sync.WaitGroup
	for _, spec := range specs {
		group.Add(1)
		go func(spec PingTargetSpec) {
			defer group.Done()
			sampler.record(spec.ID, sampler.probe(ctx, spec))
		}(spec)
	}
	group.Wait()
}

func (sampler *PingSampler) probe(ctx context.Context, spec PingTargetSpec) PingSample {
	timeout := spec.Timeout
	if timeout <= 0 {
		timeout = PingTimeout
	}
	started := sampler.Now()
	probeContext, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	err := spec.Probe(probeContext)
	elapsed := sampler.Now().Sub(started).Milliseconds()
	sample := PingSample{At: started.UTC()}
	if err != nil {
		sample.Error = err.Error()
		return sample
	}
	sample.Milliseconds = &elapsed
	return sample
}

func (sampler *PingSampler) record(id string, sample PingSample) {
	sampler.mutex.Lock()
	defer sampler.mutex.Unlock()
	if sampler.history == nil {
		sampler.history = map[string][]PingSample{}
	}
	samples := append(sampler.history[id], sample)
	if len(samples) > PingSampleLimit {
		samples = samples[len(samples)-PingSampleLimit:]
	}
	sampler.history[id] = samples
}

// Read answers the current targets with a copy of their history, so the reply
// is consistent while the sampler keeps appending.
func (sampler *PingSampler) Read() PingReport {
	specs, omissions := sampler.Specs()
	report := PingReport{Targets: make([]PingTarget, 0, len(specs)), Omitted: omissions}
	sampler.mutex.Lock()
	defer sampler.mutex.Unlock()
	for _, spec := range specs {
		samples := make([]PingSample, len(sampler.history[spec.ID]))
		copy(samples, sampler.history[spec.ID])
		report.Targets = append(report.Targets, PingTarget{ID: spec.ID, Label: spec.Label, Address: spec.Address, Samples: samples})
	}
	return report
}
