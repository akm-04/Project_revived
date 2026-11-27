package operatoragent

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestPingPlanResolvesTargetsAndOmitUnknownOnes(t *testing.T) {
	envPath := filepath.Join(t.TempDir(), "backend.env")
	if err := os.WriteFile(envPath, []byte("GXB_HTTP_ADDR=0.0.0.0:8080\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	plan := PingPlan{
		Config:    Config{Backend: BackendConfig{EnvFile: envPath, OperatorAddr: "127.0.0.1:8091"}},
		ServerURL: func() (string, string) { return "https://game.example/", ServerURLSourceEnvFile },
		PublicURLs: func() PublicURLs {
			return PublicURLs{PublicRoleSDK: "https://sdk.example/", PublicRoleAPI: "https://api.example/", PublicRoleAssets: "https://assets.example/"}
		},
		Environment: func(key string) string {
			return map[string]string{"GXB_HTTP_ADDR": "127.0.0.1:9999", "GXB_REALTIME_ADDR": "127.0.0.1:9000"}[key]
		},
	}
	specs, omissions := plan.Specs()
	if len(omissions) != 0 {
		t.Fatalf("omissions = %+v", omissions)
	}
	addresses := map[string]string{}
	for _, spec := range specs {
		addresses[spec.ID] = spec.Address
	}
	want := map[string]string{
		pingInternetID:   "1.1.1.1:443",
		pingOperatorID:   "127.0.0.1:8091",
		pingBackendAPIID: "127.0.0.1:8080",
		pingRealtimeID:   "127.0.0.1:9000",
		pingSDKURLID:     "https://sdk.example",
		pingAPIURLID:     "https://api.example",
		pingAssetsURLID:  "https://assets.example",
	}
	for id, address := range want {
		if addresses[id] != address {
			t.Fatalf("%s = %q, want %q (all: %+v)", id, addresses[id], address, addresses)
		}
	}
}

// The single GXB_PUBLIC_ENGINE_URL stays the game API address when the role
// map does not name one, so an existing installation keeps its probe.
func TestPingPlanFallsBackToTheGameURLForTheAPIRole(t *testing.T) {
	plan := PingPlan{
		ServerURL:  func() (string, string) { return "https://game.example/", ServerURLSourceEnvFile },
		PublicURLs: func() PublicURLs { return PublicURLs{} },
		Environment: func(string) string {
			return ""
		},
	}
	specs, _ := plan.Specs()
	addresses := map[string]string{}
	for _, spec := range specs {
		addresses[spec.ID] = spec.Address
	}
	if addresses[pingAPIURLID] != "https://game.example" {
		t.Fatalf("api address = %q", addresses[pingAPIURLID])
	}
}

func TestPingPlanOmitsEveryTargetWithNoAddress(t *testing.T) {
	plan := PingPlan{
		ServerURL:   func() (string, string) { return "", "" },
		Environment: func(string) string { return "" },
	}
	specs, omissions := plan.Specs()
	if len(specs) != 1 || specs[0].ID != pingInternetID {
		t.Fatalf("specs = %+v", specs)
	}
	reasons := map[string]string{}
	for _, omission := range omissions {
		reasons[omission.ID] = omission.Reason
	}
	for _, id := range []string{pingOperatorID, pingBackendAPIID, pingRealtimeID, pingSDKURLID, pingAPIURLID, pingAssetsURLID} {
		if reasons[id] == "" {
			t.Fatalf("%s has no omission reason (all: %+v)", id, omissions)
		}
	}
}

func TestPingSamplerRecordsSamplesAndCapsTheHistory(t *testing.T) {
	now := time.Unix(1000, 0).UTC()
	sampler := &PingSampler{
		Specs: func() ([]PingTargetSpec, []PingOmission) {
			return []PingTargetSpec{
				{ID: "ok", Label: "ok", Address: "ok", Timeout: time.Second, Probe: func(context.Context) error { return nil }},
				{ID: "bad", Label: "bad", Address: "bad", Timeout: time.Second, Probe: func(context.Context) error { return errors.New("connection refused") }},
			}, nil
		},
		Interval: time.Hour,
		Now:      func() time.Time { return now },
		history:  map[string][]PingSample{},
	}
	sampler.SampleOnce(context.Background())
	report := sampler.Read()
	if len(report.Targets) != 2 {
		t.Fatalf("targets = %+v", report.Targets)
	}
	ok := report.Targets[0].Samples
	if len(ok) != 1 || ok[0].Milliseconds == nil || ok[0].Error != "" {
		t.Fatalf("ok samples = %+v", ok)
	}
	bad := report.Targets[1].Samples
	if len(bad) != 1 || bad[0].Milliseconds != nil || bad[0].Error == "" {
		t.Fatalf("bad samples = %+v", bad)
	}

	for index := 0; index < PingSampleLimit+5; index++ {
		sampler.record("ok", PingSample{At: now})
	}
	if samples := sampler.Read().Targets[0].Samples; len(samples) != PingSampleLimit {
		t.Fatalf("history holds %d samples, want %d", len(samples), PingSampleLimit)
	}
}

func TestPingProbesTreatAReachableAddressAsSuccess(t *testing.T) {
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	if err := tcpPingTarget("tcp", "tcp", listener.Addr().String(), time.Second).Probe(context.Background()); err != nil {
		t.Fatalf("tcp probe: %v", err)
	}

	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, _ *http.Request) {
		writer.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer server.Close()
	if err := httpPingTarget("http", "http", server.URL, time.Second).Probe(context.Background()); err != nil {
		t.Fatalf("http probe: %v", err)
	}
}
