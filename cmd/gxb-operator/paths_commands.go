package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

// pathsSetArguments is `paths set <key> <abs path>`.
type pathsSetArguments struct {
	Key  string
	Path string
}

// silentPatchArguments is `silent-patch -s <tree> [--publish]`.
type silentPatchArguments struct {
	Tree    string
	Publish bool
}

// resArguments is `res -s <dir> [--lane recovered|res|apk]`.
type resArguments struct {
	Directory string
	Lane      string
}

// backendFolderArguments is `backend -s <folder> [--reason <text>]`.
type backendFolderArguments struct {
	Folder string
	Reason string
}

// parseBackendFolderArguments resolves the folder now, because the agent only
// accepts an absolute path and the CLI runs on the same machine.
func parseBackendFolderArguments(args []string) (backendFolderArguments, error) {
	flags := flag.NewFlagSet("backend -s", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	source := flags.String("s", "", "release folder, or a source tree to build")
	reason := flags.String("reason", "", "why the backend is updated")
	if err := flags.Parse(args); err != nil {
		return backendFolderArguments{}, err
	}
	if *source == "" {
		return backendFolderArguments{}, errors.New("usage: backend -s <folder> [--reason <text>]")
	}
	folder, err := filepath.Abs(*source)
	if err != nil {
		return backendFolderArguments{}, err
	}
	if *reason == "" {
		*reason = "update backend to " + folder
	}
	return backendFolderArguments{Folder: folder, Reason: *reason}, nil
}

func runPaths(root string, args []string) error {
	change, err := parsePathsSetArguments(args)
	if err != nil {
		return err
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	return setAgentPath(client, change.Key, change.Path, "paths set "+change.Key)
}

func parsePathsSetArguments(args []string) (pathsSetArguments, error) {
	if len(args) != 3 || args[0] != "set" {
		return pathsSetArguments{}, errors.New("usage: paths set <key> <abs path>")
	}
	return pathsSetArguments{Key: args[1], Path: args[2]}, nil
}

// runSilentPatch points the build at a client tree, builds the lane's next code
// release with the lazy refresh, and with --publish runs the existing
// maintenance publish for the number it built.
func runSilentPatch(root string, args []string) error {
	options, err := parseSilentPatchArguments(args)
	if err != nil {
		return err
	}
	tree, err := resolveClientTree(options.Tree)
	if err != nil {
		return err
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	if err := setAgentPath(client, "client_tree", tree, "silent patch: build from "+tree); err != nil {
		return err
	}
	started, err := startOTABuild(client, "code", "", false, true)
	if err != nil {
		return err
	}
	fmt.Println(strings.TrimRight(string(started.encoded), "\n"))
	operation, err := waitForOperation(client, started.OperationID, defaultBuildPollTimeout)
	if err != nil {
		return err
	}
	if !options.Publish {
		return nil
	}
	version, err := operationReleaseVersion(operation)
	if err != nil {
		return err
	}
	return publishRelease(client, version, "silent patch "+version)
}

func parseSilentPatchArguments(args []string) (silentPatchArguments, error) {
	flags := flag.NewFlagSet("silent-patch", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	tree := flags.String("s", "", "client OTA tree, or a folder holding client/ota")
	publish := flags.Bool("publish", false, "publish the built release in a maintenance window")
	if err := flags.Parse(args); err != nil {
		return silentPatchArguments{}, err
	}
	if *tree == "" {
		return silentPatchArguments{}, errors.New("usage: silent-patch -s <client OTA tree> [--publish]")
	}
	return silentPatchArguments{Tree: *tree, Publish: *publish}, nil
}

// resolveClientTree accepts the tree itself or its client/ota folder.
func resolveClientTree(tree string) (string, error) {
	absolute, err := filepath.Abs(tree)
	if err != nil {
		return "", err
	}
	if isClientTree(absolute) {
		return absolute, nil
	}
	nested := filepath.Join(absolute, "client", "ota")
	if isClientTree(nested) {
		return nested, nil
	}
	return "", fmt.Errorf("%s is neither a client OTA tree nor holds client/ota", tree)
}

func isClientTree(path string) bool {
	return isDirectory(filepath.Join(path, "src")) || isDirectory(filepath.Join(path, "patches"))
}

func isDirectory(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func runRes(root string, args []string) error {
	options, err := parseResArguments(args)
	if err != nil {
		return err
	}
	if err := operatoragent.ValidateStoredDirectory(options.Lane+" res path", options.Directory); err != nil {
		return err
	}
	field, err := resPathField(options.Lane)
	if err != nil {
		return err
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodGet, "/agent/v1/reads/agent.settings", nil)
	if err != nil {
		return err
	}
	if status != http.StatusOK {
		return printResult(status, body)
	}
	var current struct {
		OTASettings map[string]any `json:"ota_settings"`
	}
	if err := json.Unmarshal(body, &current); err != nil || current.OTASettings == nil {
		return errors.New("the agent reply carried no OTA settings")
	}
	current.OTASettings[field] = options.Directory
	return postCommand(client, "ota.settings.set", "res "+options.Lane+" "+options.Directory, current.OTASettings)
}

func parseResArguments(args []string) (resArguments, error) {
	flags := flag.NewFlagSet("res", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	source := flags.String("s", "", "absolute picture root")
	lane := flags.String("lane", "recovered", "recovered, res or apk")
	if err := flags.Parse(args); err != nil {
		return resArguments{}, err
	}
	if *source == "" {
		return resArguments{}, errors.New("usage: res -s <dir> [--lane recovered|res|apk]")
	}
	if _, err := resPathField(*lane); err != nil {
		return resArguments{}, err
	}
	return resArguments{Directory: *source, Lane: *lane}, nil
}

// resPathField maps the lane name to the settings.json field it replaces.
func resPathField(lane string) (string, error) {
	switch lane {
	case "recovered":
		return "recovered_res_path", nil
	case "res":
		return "res_path", nil
	case "apk":
		return "apk_res_path", nil
	default:
		return "", errors.New("the lane must be recovered, res or apk")
	}
}

// startedOperation is the agent's 202 answer and the body the CLI prints.
type startedOperation struct {
	OperationID string `json:"operation_id"`
	encoded     []byte
}

func startOTABuild(client *agentClient, lane, version string, rollback, lazyRefresh bool) (startedOperation, error) {
	status, body, err := client.request(http.MethodPost, "/agent/v1/ota/build", map[string]any{
		"lane": lane, "version": version, "rollback": rollback, "lazy_refresh": lazyRefresh,
	})
	if err != nil {
		return startedOperation{}, err
	}
	if status != http.StatusAccepted {
		return startedOperation{}, printResult(status, body)
	}
	var started startedOperation
	if err := json.Unmarshal(body, &started); err != nil || started.OperationID == "" {
		return startedOperation{}, errors.New("the agent reply carried no operation id")
	}
	started.encoded = body
	return started, nil
}

// publishRelease runs the existing maintenance publish and waits for it.
func publishRelease(client *agentClient, version, reason string) error {
	semanticKey, err := operatoragent.NewToken()
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/ota/publish", map[string]string{
		"version": version, "reason": reason, "semantic_key": semanticKey,
	})
	if err != nil {
		return err
	}
	return printResult(status, body)
}

// setAgentPath runs agent.paths.set for one key.
func setAgentPath(client *agentClient, key, path, reason string) error {
	return postCommand(client, "agent.paths.set", reason, map[string]string{"key": key, "path": path})
}

// postCommand sends one local command with a fresh semantic key.
func postCommand(client *agentClient, name, reason string, payload any) error {
	semanticKey, err := operatoragent.NewToken()
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/commands/"+name, map[string]any{
		"reason": reason, "semantic_key": semanticKey, "payload": payload,
	})
	if err != nil {
		return err
	}
	return printResult(status, body)
}

// operationReleaseVersion reads the version the finished build registered; the
// last step's result is {release: {version, ...}, report: {...}}.
func operationReleaseVersion(operation operatoragent.Operation) (string, error) {
	var result struct {
		Release struct {
			Version string `json:"version"`
		} `json:"release"`
	}
	if err := json.Unmarshal(operation.Result, &result); err != nil || result.Release.Version == "" {
		return "", errors.New("the build finished without a release version to publish")
	}
	return result.Release.Version, nil
}
