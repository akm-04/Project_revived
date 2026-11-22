package otarelease

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func moduleCommand(t *testing.T, module operator.Module, name string) operator.CommandSpec {
	t.Helper()
	for _, command := range module.Commands {
		if command.Name == name {
			return command
		}
	}
	t.Fatalf("module %s does not declare %s", module.ID, name)
	return operator.CommandSpec{}
}

func TestOTAModuleRefusesEachDeclaredRequiredFieldWhenMissing(t *testing.T) {
	commands := Commands{Store: newFakeStore()}
	module := commands.Module()
	scope := tx.Scope{Tx: noTx{}, Operation: operation.Context{StartedAt: time.Unix(1, 0)}}
	fixtures := map[string]map[string]any{
		"ota.register_build": {
			"version": "1.0.0", "lane": "code", "package_files": []any{}, "total_size": 1,
			"md5": strings.Repeat("a", 32), "sha256": strings.Repeat("b", 64),
			"manifest": map[string]any{"files": []any{}}, "rollback": false,
		},
		"ota.publish":  {"version": "1.0.0"},
		"ota.withdraw": {"version": "1.0.0"},
	}
	for name, fixture := range fixtures {
		spec := moduleCommand(t, module, name)
		for _, field := range spec.Fields {
			if !field.Required {
				continue
			}
			payload := make(map[string]any, len(fixture))
			for key, value := range fixture {
				payload[key] = value
			}
			delete(payload, field.Name)
			encoded, err := json.Marshal(payload)
			if err != nil {
				t.Fatal(err)
			}
			_, err = spec.Handler(context.Background(), scope, operator.Command{ModuleCommand: name, Payload: encoded, Envelope: operator.Envelope{SemanticKey: "key"}})
			var refusal *operator.Refusal
			if !errors.As(err, &refusal) {
				t.Fatalf("%s without %s: err = %v", name, field.Name, err)
			}
		}
	}
}

func TestOTASettingsFieldsComeFromTheDomainSettings(t *testing.T) {
	module := Commands{}.Module()
	spec := moduleCommand(t, module, "ota.settings.set")
	if len(spec.Fields) != 0 && spec.Fields[0].Required {
		t.Fatal("ota.settings.set has no required field: the payload is a complete settings object")
	}
	defaults := domain.DefaultSettings()
	fields := make(map[string]operator.Field, len(spec.Fields))
	for _, field := range spec.Fields {
		fields[field.Name] = field
	}
	encoded, err := json.Marshal(defaults)
	if err != nil {
		t.Fatal(err)
	}
	var document map[string]any
	if err := json.Unmarshal(encoded, &document); err != nil {
		t.Fatal(err)
	}
	if len(fields) != len(document) {
		t.Fatalf("module declares %d settings fields, the domain settings hold %d", len(fields), len(document))
	}
	for key := range document {
		if _, declared := fields[key]; !declared {
			t.Fatalf("settings field %s is missing from the module", key)
		}
	}
	integerBounds := map[string]struct {
		value          int64
		minimum, maxum int64
	}{
		"download_base_seconds":       {int64(defaults.DownloadBaseSeconds), domain.MinDownloadBaseSeconds, domain.MaxDownloadBaseSeconds},
		"download_min_kib_per_second": {int64(defaults.DownloadMinKiBPerSecond), domain.MinDownloadMinKiBPerSecond, domain.MaxDownloadMinKiBPerSecond},
		"cache_max_age_seconds":       {int64(defaults.CacheMaxAgeSeconds), domain.MinCacheMaxAgeSeconds, domain.MaxCacheMaxAgeSeconds},
		"serving_refresh_seconds":     {int64(defaults.ServingRefreshSeconds), domain.MinServingRefreshSeconds, domain.MaxServingRefreshSeconds},
		"volume_mb":                   {int64(defaults.VolumeMB), domain.MinVolumeMB, domain.MaxVolumeMB},
	}
	for name, want := range integerBounds {
		field := fields[name]
		if field.Minimum == nil || field.Maximum == nil || *field.Minimum != want.minimum || *field.Maximum != want.maxum {
			t.Fatalf("%s bounds = %v..%v", name, field.Minimum, field.Maximum)
		}
		defaultValue, isInt := field.Default.(int)
		if !isInt || int64(defaultValue) != want.value {
			t.Fatalf("%s default = %v, want %v", name, field.Default, want.value)
		}
	}
	if fields["lazy_fetch"].Default != string(defaults.LazyFetch) || len(fields["lazy_fetch"].Enum) != 3 {
		t.Fatalf("lazy_fetch = %+v", fields["lazy_fetch"])
	}
	if fields["res_path"].Default != defaults.ResPath {
		t.Fatalf("res_path default = %v", fields["res_path"].Default)
	}
}

func TestOTAModuleCoversEveryRegisteredHandler(t *testing.T) {
	commands := Commands{}
	module := commands.Module()
	for name := range commands.Handlers() {
		spec := moduleCommand(t, module, name)
		if spec.Handler == nil {
			t.Fatalf("%s has a bus handler but no module handler", name)
		}
	}
}

func TestOTAModuleDeclaresEveryLiveCommand(t *testing.T) {
	module := Commands{}.Module()
	if len(module.Commands) != 4 {
		t.Fatalf("commands = %+v", module.Commands)
	}
	settings := moduleCommand(t, module, "ota.settings.set")
	if settings.Handler != nil {
		t.Fatal("the settings handler is bound by the composition root, not the owner value")
	}
	if len(module.Reads) != 2 {
		t.Fatalf("reads = %+v", module.Reads)
	}
}
