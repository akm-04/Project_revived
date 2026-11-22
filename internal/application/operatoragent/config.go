package operatoragent

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strings"
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
)

// BackendConfig names the backend binary the agent controls.
type BackendConfig struct {
	Binary       string `json:"binary"`
	EnvFile      string `json:"env_file"`
	OperatorAddr string `json:"operator_addr"`
}

// Config is agent.json: the agent root folder's configuration. Unknown fields
// are refused so a typo never silently changes behaviour.
type Config struct {
	Listen        string            `json:"listen"`
	OTARoot       string            `json:"ota_root"`
	StockBaseline string            `json:"stock_baseline"`
	ClientTree    string            `json:"client_tree"`
	Origins       map[string]string `json:"origins"`
	Backend       BackendConfig     `json:"backend"`
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
	if err := ensureEndOfFile(decoder); err != nil {
		return Config{}, fmt.Errorf("%s: %w", AgentConfigFileName, err)
	}
	if err := config.Validate(); err != nil {
		return Config{}, err
	}
	return config, nil
}

func ensureEndOfFile(decoder *json.Decoder) error {
	var extra any
	if err := decoder.Decode(&extra); errors.Is(err, io.EOF) {
		return nil
	} else if err != nil {
		return err
	}
	return errors.New("trailing data after the JSON object")
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
