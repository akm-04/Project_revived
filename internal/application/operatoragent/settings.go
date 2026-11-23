package operatoragent

import (
	"errors"
	"net/url"
	"os"
	"path/filepath"
	"strings"

	appotarelease "gxb.local/backend/v2/internal/application/otarelease"
	domainotarelease "gxb.local/backend/v2/internal/domain/otarelease"
)

// PublicEngineURLKey is the backend environment key the client's game URL comes
// from: MID 20480 replies with it (UpdateScene.lua:165) and the client stores it
// as xyd.serverUrl.
const PublicEngineURLKey = "GXB_PUBLIC_ENGINE_URL"

// The two places the agent can learn the client-facing URL from: the backend
// env file first, then its own process environment (the backend inherits it
// when agent.json names no env file).
const (
	ServerURLSourceEnvFile          = "env_file"
	ServerURLSourceAgentEnvironment = "agent_environment"
)

// SettingsService reads and writes the two operator settings files: agent.json
// (backend, backup, toolchain and app_repack paths) and the backend env file
// (the public engine URL). The OTA paths live in settings.json and are changed
// through ota.settings.set; Values reads them for the GUI.
type SettingsService struct {
	Root    string
	OTARoot string
	// LookupEnvironment reads the agent process environment; nil means
	// os.Getenv. Tests set it to prove the fallback without touching the
	// process environment.
	LookupEnvironment func(string) string
}

// AgentSettingsValues is the read the Settings page and the dashboard show.
type AgentSettingsValues struct {
	ServerURL        string                    `json:"server_url"`
	ServerURLSource  string                    `json:"server_url_source"`
	BackendPath      string                    `json:"backend_path"`
	EnvFile          string                    `json:"env_file"`
	ResPath          string                    `json:"res_path"`
	ApkResPath       string                    `json:"apk_res_path"`
	RecoveredResPath string                    `json:"recovered_res_path"`
	BackupPath       string                    `json:"backup_path"`
	AppRepackPath    string                    `json:"app_repack_path"`
	ToolchainPath    string                    `json:"toolchain_path"`
	OTASettings      domainotarelease.Settings `json:"ota_settings"`
}

// AgentSettingsChange is the agent.settings.set payload. A nil field is
// unchanged; an empty toolchain or backup path restores its default.
type AgentSettingsChange struct {
	BackendPath   *string `json:"backend_path,omitempty"`
	BackupPath    *string `json:"backup_path,omitempty"`
	AppRepackPath *string `json:"app_repack_path,omitempty"`
	ToolchainPath *string `json:"toolchain_path,omitempty"`
}

// AgentSettingsReply says the write succeeded and that agent.json is read only
// at agent start.
type AgentSettingsReply struct {
	Values          AgentSettingsValues `json:"values"`
	RestartRequired bool                `json:"restart_required"`
	Message         string              `json:"message"`
}

// ServerURLReply is the server.url.set result; the APK carries the prelogin URL
// that asks the backend for this value, so a change needs a rebuilt APK (S3b).
type ServerURLReply struct {
	URL                string `json:"url"`
	RestartRequired    bool   `json:"restart_required"`
	APKRebuildRequired bool   `json:"apk_rebuild_required"`
	Message            string `json:"message"`
}

// Values reads the current settings best effort: a missing env file or
// settings.json is the documented default, never a broken page (F1).
func (service SettingsService) Values() (AgentSettingsValues, error) {
	config, err := ReadConfig(service.Root)
	if err != nil {
		return AgentSettingsValues{}, err
	}
	otaSettings, err := appotarelease.SettingsFile{Root: service.OTARoot}.Load()
	if err != nil {
		return AgentSettingsValues{}, err
	}
	serverURL, source, err := service.serverURL(config)
	if err != nil {
		return AgentSettingsValues{}, err
	}
	return AgentSettingsValues{
		ServerURL:        serverURL,
		ServerURLSource:  source,
		BackendPath:      config.Backend.Binary,
		EnvFile:          config.Backend.EnvFile,
		ResPath:          otaSettings.ResPath,
		ApkResPath:       otaSettings.ApkResPath,
		RecoveredResPath: otaSettings.RecoveredResPath,
		BackupPath:       config.BackupDirectory(service.Root),
		AppRepackPath:    config.AppRepackPath,
		ToolchainPath:    config.ToolchainPath,
		OTASettings:      otaSettings,
	}, nil
}

// serverURL reads the client-facing URL in the backend's own precedence: the
// env file entry first, then the agent's process environment, which the
// started backend inherits. The source tells the GUI where the value came from
// so a read-only environment value is not mistaken for a missing setting.
func (service SettingsService) serverURL(config Config) (string, string, error) {
	fromFile, err := ReadEnvValue(config.Backend.EnvFile, PublicEngineURLKey)
	if err != nil {
		return "", "", err
	}
	if fromFile != "" {
		return fromFile, ServerURLSourceEnvFile, nil
	}
	fromEnvironment := service.environment(PublicEngineURLKey)
	if fromEnvironment != "" {
		return fromEnvironment, ServerURLSourceAgentEnvironment, nil
	}
	return "", "", nil
}

func (service SettingsService) environment(key string) string {
	if service.LookupEnvironment != nil {
		return service.LookupEnvironment(key)
	}
	return os.Getenv(key)
}

// SetAgent applies the supplied paths to agent.json. Every value is validated
// before the file is replaced, so a refused value keeps the old one (F1).
func (service SettingsService) SetAgent(change AgentSettingsChange) (AgentSettingsReply, error) {
	config, err := ReadConfig(service.Root)
	if err != nil {
		return AgentSettingsReply{}, Refuse(CodeSettingsUnavailable, "agent.json is unreadable: "+err.Error())
	}
	if change.BackendPath != nil {
		value := strings.TrimSpace(*change.BackendPath)
		if err := ValidateBackendBinary(value); err != nil {
			return AgentSettingsReply{}, Refuse(CodeSettingsInvalid, err.Error())
		}
		config.Backend.Binary = value
	}
	if change.BackupPath != nil {
		config.BackupPath = strings.TrimSpace(*change.BackupPath)
	}
	if change.AppRepackPath != nil {
		value := strings.TrimSpace(*change.AppRepackPath)
		if err := validateReadableDirectory("app_repack_path", value); err != nil {
			return AgentSettingsReply{}, Refuse(CodeSettingsInvalid, err.Error())
		}
		config.AppRepackPath = value
	}
	if change.ToolchainPath != nil {
		config.ToolchainPath = strings.TrimSpace(*change.ToolchainPath)
	}
	if err := config.Validate(); err != nil {
		return AgentSettingsReply{}, Refuse(CodeSettingsInvalid, err.Error())
	}
	if config.Backend.EnvFile != "" {
		info, statErr := os.Stat(config.Backend.EnvFile)
		if statErr != nil || info.IsDir() {
			return AgentSettingsReply{}, Refuse(CodeSettingsInvalid, "the backend env file is not readable")
		}
	}
	if err := SaveConfig(service.Root, config); err != nil {
		return AgentSettingsReply{}, Temporarily(CodeFailed, "agent.json cannot be written")
	}
	values, _ := service.Values()
	return AgentSettingsReply{
		Values:          values,
		RestartRequired: true,
		Message:         "Restart the operator agent for these paths to take effect.",
	}, nil
}

// SetServerURL writes GXB_PUBLIC_ENGINE_URL into the backend env file, which is
// the only place the backend reads the client-facing URL from.
func (service SettingsService) SetServerURL(raw string) (ServerURLReply, error) {
	normalized, err := NormalizePublicEngineURL(raw)
	if err != nil {
		return ServerURLReply{}, err
	}
	config, err := ReadConfig(service.Root)
	if err != nil {
		return ServerURLReply{}, Refuse(CodeSettingsUnavailable, "agent.json is unreadable: "+err.Error())
	}
	if config.Backend.EnvFile == "" {
		return ServerURLReply{}, Refuse(CodeSettingsUnavailable, "This install has no backend env file, so the agent cannot save the server URL here. Set an env file in agent.json to change it from this page.")
	}
	if err := WriteEnvValue(config.Backend.EnvFile, PublicEngineURLKey, normalized); err != nil {
		return ServerURLReply{}, Refuse(CodeSettingsUnavailable, "the backend env file cannot be written: "+err.Error())
	}
	return ServerURLReply{
		URL:                normalized,
		RestartRequired:    true,
		APKRebuildRequired: true,
		Message:            "Restart the backend to apply the URL. The APK must be rebuilt with this URL (app_repack), because the APK carries the address that asks for it.",
	}, nil
}

// NormalizePublicEngineURL accepts the absolute http or https address the client
// can reach; a query, fragment or embedded credentials are refused.
func NormalizePublicEngineURL(raw string) (string, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "", Refuse(CodeServerURLInvalid, "the server URL is required")
	}
	parsed, err := url.Parse(trimmed)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Host == "" {
		return "", Refuse(CodeServerURLInvalid, "the server URL must be an absolute http or https address")
	}
	if parsed.User != nil || parsed.RawQuery != "" || parsed.Fragment != "" {
		return "", Refuse(CodeServerURLInvalid, "the server URL must not carry credentials, a query or a fragment")
	}
	return strings.TrimRight(trimmed, "/"), nil
}

func validateReadableDirectory(name, path string) error {
	if path == "" {
		return nil
	}
	if !filepath.IsAbs(path) {
		return errors.New(name + " must be absolute")
	}
	info, err := os.Stat(path)
	if err != nil || !info.IsDir() {
		return errors.New(name + " is not a readable folder")
	}
	return nil
}
