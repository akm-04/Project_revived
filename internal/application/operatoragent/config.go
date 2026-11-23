package operatoragent

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"runtime"
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
	BackupDirectoryName = "backups"
	DefaultAgentListen  = "127.0.0.1:8090"
	DefaultOperatorAddr = "127.0.0.1:8091"

	DefaultReadyTimeoutSeconds = 60
	DefaultStopGraceSeconds    = 15
	minReadyTimeoutSeconds     = 5
	maxReadyTimeoutSeconds     = 600
	minStopGraceSeconds        = 1
	maxStopGraceSeconds        = 300

	// DefaultBackupKeep is B1/F1: the last five snapshots are kept with no
	// operator input; backup_keep below 1 is refused.
	DefaultBackupKeep = 5
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
	// ToolLogDays is the age retention of the tool and backend log files (C1);
	// nil means DefaultToolLogDays.
	ToolLogDays *int `json:"tool_log_days,omitempty"`
	// DatabaseLog is the PostgreSQL log file the logs tab reads (C1 c). Empty
	// means the database source answers ABSENT.
	DatabaseLog string `json:"database_log,omitempty"`
	// BackupPath defaults to <agent root>/backups (P3); BackupKeep to 5 (B1).
	BackupPath string `json:"backup_path,omitempty"`
	BackupKeep *int   `json:"backup_keep,omitempty"`
	// ToolchainPath is the P2 portable tools folder; unset means the agent's
	// own PATH (the system-wide P2 choice).
	ToolchainPath string `json:"toolchain_path,omitempty"`
	// AppRepackPath is the S3b APK build folder (app_repack).
	AppRepackPath string `json:"app_repack_path,omitempty"`
}

// BackupDirectory resolves the snapshot folder: the configured path, else
// <agent root>/backups (P3).
func (config Config) BackupDirectory(root string) string {
	if config.BackupPath != "" {
		return config.BackupPath
	}
	return filepath.Join(root, BackupDirectoryName)
}

// BackupKeepValue resolves the retained snapshot count: the configured value,
// else DefaultBackupKeep (B1).
func (config Config) BackupKeepValue() int {
	if config.BackupKeep == nil {
		return DefaultBackupKeep
	}
	return *config.BackupKeep
}

// ToolLogRetentionDays is tool_log_days with the safe default (F1).
func (config Config) ToolLogRetentionDays() int {
	if config.ToolLogDays == nil {
		return DefaultToolLogDays
	}
	return *config.ToolLogDays
}

// LoadConfig reads and validates <root>/agent.json.
func LoadConfig(root string) (Config, error) {
	config, err := ReadConfig(root)
	if err != nil {
		return Config{}, err
	}
	if err := config.Validate(); err != nil {
		return Config{}, err
	}
	return config, nil
}

// ReadConfig reads <root>/agent.json without validating it, so the operator GUI
// can still show a setting whose folder has gone away (F1).
func ReadConfig(root string) (Config, error) {
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
	return config, nil
}

// SaveConfig replaces <root>/agent.json atomically. The caller validates first;
// a refused value never reaches this function, so the old file stays.
func SaveConfig(root string, config Config) error {
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	temporary, err := os.CreateTemp(root, ".agent-*.json")
	if err != nil {
		return fmt.Errorf("write %s: %w", AgentConfigFileName, err)
	}
	temporaryName := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryName)
	}
	if _, err := temporary.Write(append(data, '\n')); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if err := os.Rename(temporaryName, filepath.Join(root, AgentConfigFileName)); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	return nil
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
	if value := config.BackupKeep; value != nil && *value < 1 {
		return fmt.Errorf("%s: backup_keep %d must be at least 1", AgentConfigFileName, *value)
	}
	if config.BackupPath != "" {
		if !filepath.IsAbs(config.BackupPath) {
			return errors.New(AgentConfigFileName + ": backup_path must be absolute")
		}
		for name, tree := range config.protectedTrees() {
			if tree != "" && pathWithin(config.BackupPath, tree) {
				return fmt.Errorf("%s: backup_path must not be inside %s", AgentConfigFileName, name)
			}
		}
		if err := ensureWritableDirectory(config.BackupPath); err != nil {
			return fmt.Errorf("%s: backup_path is not writable: %w", AgentConfigFileName, err)
		}
	}
	if config.ToolchainPath != "" {
		info, err := os.Stat(config.ToolchainPath)
		if err != nil || !info.IsDir() {
			return errors.New(AgentConfigFileName + ": toolchain_path is not a readable directory")
		}
	}
	if value := config.ToolLogDays; value != nil && (*value < 1 || *value > maximumToolLogDays) {
		return fmt.Errorf("%s: tool_log_days %d is outside 1..%d", AgentConfigFileName, *value, maximumToolLogDays)
	}
	return nil
}

// protectedTrees are the res and backend trees B1 keeps the backup folder out
// of: the OTA root (res), the client tree, the stock sources and the backend
// binary's folder.
func (config Config) protectedTrees() map[string]string {
	trees := map[string]string{
		"ota_root":     config.OTARoot,
		"client_tree":  config.ClientTree,
		"stock_source": config.StockSource,
	}
	if config.Backend.Binary != "" {
		trees["backend_binary"] = filepath.Dir(config.Backend.Binary)
	}
	return trees
}

func pathWithin(child, parent string) bool {
	childPath, err := filepath.Abs(child)
	if err != nil {
		return false
	}
	parentPath, err := filepath.Abs(parent)
	if err != nil {
		return false
	}
	relative, err := filepath.Rel(parentPath, childPath)
	if err != nil {
		return false
	}
	return relative == "." || (relative != ".." && !strings.HasPrefix(relative, ".."+string(os.PathSeparator)))
}

func ensureWritableDirectory(path string) error {
	if err := os.MkdirAll(path, 0o700); err != nil {
		return err
	}
	probe, err := os.CreateTemp(path, ".backup-write-check-*")
	if err != nil {
		return err
	}
	name := probe.Name()
	_ = probe.Close()
	return os.Remove(name)
}

func isLoopbackAddress(address string) bool {
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return false
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

// ValidateBackendBinary is the P1 check of the backend path the agent starts:
// an absolute path to a regular, executable file.
func ValidateBackendBinary(path string) error {
	if path == "" {
		return errors.New("the backend path is required")
	}
	if !filepath.IsAbs(path) {
		return errors.New("the backend path must be absolute")
	}
	info, err := os.Stat(path)
	if err != nil {
		return errors.New("the backend path does not exist")
	}
	if !info.Mode().IsRegular() {
		return errors.New("the backend path is not a file")
	}
	if runtime.GOOS != "windows" && info.Mode()&0o111 == 0 {
		return errors.New("the backend path is not executable")
	}
	return nil
}

// ReadEnvValue returns the value of one key in the backend env file; a missing
// file or key is the empty value, so an unset setting never breaks the GUI (F1).
func ReadEnvValue(path, key string) (string, error) {
	if path == "" {
		return "", nil
	}
	entries, err := ReadEnvFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", nil
		}
		return "", err
	}
	prefix := key + "="
	for _, entry := range entries {
		if value, found := strings.CutPrefix(entry, prefix); found {
			return value, nil
		}
	}
	return "", nil
}

// WriteEnvValue replaces one key in the backend env file and keeps every other
// line and comment; the file is written atomically so a reader never sees a
// half-written environment.
func WriteEnvValue(path, key, value string) error {
	if path == "" {
		return errors.New("the backend env file is not configured")
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read env_file: %w", err)
	}
	prefix := key + "="
	lines := strings.Split(strings.ReplaceAll(string(contents), "\r\n", "\n"), "\n")
	replaced := false
	for index, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), prefix) {
			lines[index] = prefix + value
			replaced = true
			break
		}
	}
	if !replaced {
		if len(lines) > 0 && lines[len(lines)-1] == "" {
			lines = lines[:len(lines)-1]
		}
		lines = append(lines, prefix+value, "")
	}
	temporary, err := os.CreateTemp(filepath.Dir(path), ".env-*")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryName)
	}
	if _, err := temporary.Write([]byte(strings.Join(lines, "\n"))); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if err := os.Rename(temporaryName, path); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	return nil
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
