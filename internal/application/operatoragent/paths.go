package operatoragent

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"gxb.local/backend/v2/internal/application/otabuild"
)

// PathsChange is the agent.paths.set payload: one agent.json path per command,
// so a refused value keeps every other stored path.
type PathsChange struct {
	Key  string `json:"key"`
	Path string `json:"path"`
}

// PathsReply says the write succeeded and whether the agent reads the value
// live. The OTA build inputs are read again at each build; the OTA root and the
// media folder are fixed when the agent starts.
type PathsReply struct {
	RestartRequired bool   `json:"restart_required"`
	Message         string `json:"message"`
}

// PathsService writes the agent.json folders the OTA build reads. It lives in
// the agent because only the agent's machine has these folders.
type PathsService struct {
	Root    string
	Backend BackendControl
}

// pathSetters is the one list of agent.paths.set keys; an unknown key is a
// refusal rather than a new field.
var pathSetters = map[string]struct {
	set   func(*Config, string)
	label string
}{
	"client_tree":    {func(config *Config, value string) { config.ClientTree = value }, "client tree"},
	"stock_baseline": {func(config *Config, value string) { config.StockBaseline = value }, "stock baseline"},
	"stock_source":   {func(config *Config, value string) { config.StockSource = value }, "stock source"},
	"stock_catalog":  {func(config *Config, value string) { config.StockCatalog = value }, "stock catalogue"},
	"ota_root":       {func(config *Config, value string) { config.OTARoot = value }, "OTA root"},
	"media_path":     {func(config *Config, value string) { config.MediaPath = value }, "media folder"},
}

// Set validates one path and saves agent.json atomically. An existing backend
// child keeps the old OTA root, so changing it needs the backend stopped.
func (service PathsService) Set(change PathsChange) (PathsReply, error) {
	key := strings.TrimSpace(change.Key)
	value := strings.TrimSpace(change.Path)
	setter, known := pathSetters[key]
	if !known {
		return PathsReply{}, Refuse(CodeSettingsInvalid, fmt.Sprintf("unknown path %q; use client_tree, stock_baseline, stock_source, stock_catalog, ota_root or media_path", key))
	}
	if err := ValidateStoredDirectory(key, value); err != nil {
		return PathsReply{}, Refuse(CodeSettingsInvalid, err.Error())
	}
	if key == "client_tree" {
		if err := validateClientTree(value); err != nil {
			return PathsReply{}, Refuse(CodeSettingsInvalid, err.Error())
		}
	}
	config, err := ReadConfig(service.Root)
	if err != nil {
		return PathsReply{}, Refuse(CodeSettingsUnavailable, "agent.json is unreadable: "+err.Error())
	}
	if key == "ota_root" && service.Backend != nil && service.Backend.Status().Running {
		return PathsReply{}, Refuse(CodeBackendRunning, "stop the backend before changing ota_root")
	}
	setter.set(&config, value)
	if err := config.Validate(); err != nil {
		return PathsReply{}, Refuse(CodeSettingsInvalid, err.Error())
	}
	if err := SaveConfig(service.Root, config); err != nil {
		return PathsReply{}, Temporarily(CodeFailed, "agent.json cannot be written")
	}
	if key == "ota_root" || key == "media_path" {
		return PathsReply{RestartRequired: true, Message: fmt.Sprintf("The %s is saved; restart the operator agent to apply it.", setter.label)}, nil
	}
	return PathsReply{Message: fmt.Sprintf("The %s is saved; the next OTA build reads it.", setter.label)}, nil
}

// validateClientTree enforces the build's client-tree shape: the patch folders,
// or the replacement files under src/.
func validateClientTree(path string) error {
	patched, err := otabuild.PatchesPresent(path)
	if err != nil {
		return err
	}
	if patched {
		return nil
	}
	info, err := os.Stat(filepath.Join(path, "src"))
	if err != nil || !info.IsDir() {
		return errors.New("client_tree must contain src/ or patches/")
	}
	return nil
}

// ValidateStoredDirectory is the rule every stored folder follows: absolute, an
// existing folder, and no symlinks in the path or below it.
func ValidateStoredDirectory(name, path string) error {
	if path == "" {
		return fmt.Errorf("%s is required", name)
	}
	if !filepath.IsAbs(path) {
		return fmt.Errorf("%s must be absolute", name)
	}
	info, err := os.Lstat(path)
	if err != nil {
		return fmt.Errorf("%s is not a readable folder", name)
	}
	if info.Mode()&os.ModeSymlink != 0 {
		return fmt.Errorf("%s must not be a symlink", name)
	}
	if !info.IsDir() {
		return fmt.Errorf("%s is not a folder", name)
	}
	walkErr := filepath.WalkDir(path, func(current string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if current != path && entry.Type()&os.ModeSymlink != 0 {
			return symlinkedPathError{path: current}
		}
		return nil
	})
	if walkErr != nil {
		var linked symlinkedPathError
		if errors.As(walkErr, &linked) {
			return fmt.Errorf("%s contains a symlink at %s", name, linked.path)
		}
		return fmt.Errorf("%s cannot be read: %v", name, walkErr)
	}
	return nil
}

type symlinkedPathError struct {
	path string
}

func (linked symlinkedPathError) Error() string { return linked.path }
