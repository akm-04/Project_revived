package operatoragent

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/application/otabuild"
	"gxb.local/backend/v2/internal/foundation/jsonbody"
)

const (
	AgentConfigFileName = "agent.json"
	PasswordFileName    = "root.passwd"
	SessionFileName     = "cli.session"
	LogsDirectoryName   = "logs"
	OperationsDirectory = "ops"
	ToolLogFileName     = "tool.log"
	BackendLogFileName  = "backend.log"
	DefaultAgentListen  = "127.0.0.1:8090"
	DefaultOperatorAddr = "127.0.0.1:8091"

	DefaultReadyTimeoutSeconds = 60
	DefaultStopGraceSeconds    = 15
	minReadyTimeoutSeconds     = 5
	maxReadyTimeoutSeconds     = 600
	minStopGraceSeconds        = 1
	maxStopGraceSeconds        = 300
)

// BackendConfig names the backend binary the agent controls.
type BackendConfig struct {
	Binary       string `json:"binary"`
	EnvFile      string `json:"env_file"`
	OperatorAddr string `json:"operator_addr"`
	// ReadyTimeoutSeconds and StopGraceSeconds are optional; nil means the
	// default. A pointer separates a missing field from an explicit 0.
	ReadyTimeoutSeconds *int `json:"ready_timeout_seconds,omitempty"`
	StopGraceSeconds    *int `json:"stop_grace_seconds,omitempty"`
}

// ReadyTimeout is how long the agent waits for the backend to answer.
func (config BackendConfig) ReadyTimeout() time.Duration {
	if config.ReadyTimeoutSeconds == nil {
		return DefaultReadyTimeoutSeconds * time.Second
	}
	return time.Duration(*config.ReadyTimeoutSeconds) * time.Second
}

// StopGrace is how long the agent waits before killing the backend.
func (config BackendConfig) StopGrace() time.Duration {
	if config.StopGraceSeconds == nil {
		return DefaultStopGraceSeconds * time.Second
	}
	return time.Duration(*config.StopGraceSeconds) * time.Second
}

// Config is agent.json: the agent root folder's configuration. Unknown fields
// are refused so a typo never silently changes behaviour.
type Config struct {
	Listen        string            `json:"listen"`
	OTARoot       string            `json:"ota_root"`
	StockBaseline string            `json:"stock_baseline"`
	StockSource   string            `json:"stock_source,omitempty"`
	StockCatalog  string            `json:"stock_catalog,omitempty"`
	ClientTree    string            `json:"client_tree"`
	Origins       map[string]string `json:"origins"`
	// PublicURLs are the tunnel and LAN addresses the dashboard shows (S3).
	// Empty until the operator sets them; the dashboard still renders (F1).
	PublicURLs []string      `json:"public_urls,omitempty"`
	Backend    BackendConfig `json:"backend"`
}

// LoadConfig reads and validates <root>/agent.json.
func LoadConfig(root string) (Config, error) {
	path := root + string(os.PathSeparator) + AgentConfigFileName
	contents, err := os.ReadFile(path)
	if err != nil {
		return Config{}, fmt.Errorf("read %s: %w", AgentConfigFileName, err)
	}
	decoder := json.NewDecoder(bytes.NewReader(contents))
	decoder.DisallowUnknownFields()
	var config Config
	if err := decoder.Decode(&config); err != nil {
		return Config{}, fmt.Errorf("%s: %w", AgentConfigFileName, err)
	}
	if err := jsonbody.EnsureEndOfFile(decoder); err != nil {
		return Config{}, fmt.Errorf("%s: %w", AgentConfigFileName, err)
	}
	if err := config.Validate(); err != nil {
		return Config{}, err
	}
	return config, nil
}

// Validate enforces the loopback-only rule (I11A_ARCHITECTURE_V1 section 6).
func (config Config) Validate() error {
	if config.Listen == "" {
		return errors.New(AgentConfigFileName + ": listen is required")
	}
	if !isLoopbackAddress(config.Listen) {
		return errors.New(AgentConfigFileName + ": listen must be a loopback address")
	}
	if config.Backend.OperatorAddr == "" {
		return errors.New(AgentConfigFileName + ": backend.operator_addr is required")
	}
	if !isLoopbackAddress(config.Backend.OperatorAddr) {
		return errors.New(AgentConfigFileName + ": backend.operator_addr must be a loopback address")
	}
	if config.StockSource != "" {
		info, err := os.Stat(config.StockSource)
		if err != nil || !info.IsDir() {
			return errors.New(AgentConfigFileName + ": stock_source is not a readable directory")
		}
	}
	if config.ClientTree != "" {
		patched, err := otabuild.PatchesPresent(config.ClientTree)
		if err != nil {
			return fmt.Errorf("%s: %v", AgentConfigFileName, err)
		}
		if patched && config.StockSource == "" {
			return errors.New(AgentConfigFileName + ": stock_source is required while the client tree has a patch")
		}
	}
	if value := config.Backend.ReadyTimeoutSeconds; value != nil && (*value < minReadyTimeoutSeconds || *value > maxReadyTimeoutSeconds) {
		return fmt.Errorf("%s: backend.ready_timeout_seconds %d is outside %d..%d", AgentConfigFileName, *value, minReadyTimeoutSeconds, maxReadyTimeoutSeconds)
	}
	if value := config.Backend.StopGraceSeconds; value != nil && (*value < minStopGraceSeconds || *value > maxStopGraceSeconds) {
		return fmt.Errorf("%s: backend.stop_grace_seconds %d is outside %d..%d", AgentConfigFileName, *value, minStopGraceSeconds, maxStopGraceSeconds)
	}
	return nil
}

func isLoopbackAddress(address string) bool {
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return false
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

// ReadEnvFile returns the KEY=VALUE lines of the backend env file. Comments
// (lines whose first non-space character is '#') and blank lines are skipped;
// the first '=' separates the key from a value that may itself contain '='.
// Error text never quotes the line, because a line can hold a secret.
func ReadEnvFile(path string) ([]string, error) {
	contents, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read env_file: %w", err)
	}
	text := strings.ReplaceAll(string(contents), "\r\n", "\n")
	lines := strings.Split(text, "\n")
	entries := make([]string, 0, len(lines))
	for index, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}
		if strings.IndexByte(trimmed, '=') <= 0 {
			return nil, fmt.Errorf("env_file line %d is not KEY=VALUE", index+1)
		}
		entries = append(entries, trimmed)
	}
	return entries, nil
}
