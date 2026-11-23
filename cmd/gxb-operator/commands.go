package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"text/tabwriter"
	"time"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

func runClientCommand(root, command string, remaining []string) error {
	switch command {
	case "setup":
		return runSetup(root)
	case "login":
		return runLogin(root)
	case "logout":
		return runLogout(root)
	case "reset-password":
		return runResetPassword(root)
	case "backend":
		return runBackend(root, remaining)
	case "cmd":
		return runCommand(root, remaining)
	case "read":
		return runRead(root, remaining)
	case "ota":
		return runOTA(root, remaining)
	case "backup":
		return runBackup(root, remaining)
	case "op":
		return runOperation(root, remaining)
	case "modules":
		return runModules(root, remaining)
	default:
		return runLog(root, remaining)
	}
}

func runSetup(root string) error {
	password, err := readPassword("Root password: ")
	if err != nil {
		return err
	}
	confirmation, err := readPassword("Repeat password: ")
	if err != nil {
		return err
	}
	if password != confirmation {
		return errors.New("the passwords do not match")
	}
	client, err := newAgentClient(root, false)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/setup", map[string]string{"password": password})
	if err != nil {
		return err
	}
	return printResult(status, body)
}

type loginReply struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

func runLogin(root string) error {
	password, err := readPassword("Password: ")
	if err != nil {
		return err
	}
	client, err := newAgentClient(root, false)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/login", map[string]string{"password": password})
	if err != nil {
		return err
	}
	if status < 200 || status >= 300 {
		return printResult(status, body)
	}
	var reply loginReply
	if err := json.Unmarshal(body, &reply); err != nil || reply.Token == "" {
		return errors.New("the agent login reply carried no token")
	}
	if err := os.WriteFile(filepath.Join(root, operatoragent.SessionFileName), []byte(reply.Token+"\n"), 0o600); err != nil {
		return err
	}
	fmt.Printf("logged in; the session expires at %s\n", reply.ExpiresAt.Format(time.RFC3339))
	return nil
}

// runResetPassword changes the root password by writing the root folder file
// directly: a forgotten password never needs the agent or a network path. The
// new generation ends every live agent session on its next request (design A.2).
func runResetPassword(root string) error {
	password, err := readPassword("New password: ")
	if err != nil {
		return err
	}
	confirmation, err := readPassword("Repeat password: ")
	if err != nil {
		return err
	}
	if password != confirmation {
		return errors.New("the passwords do not match")
	}
	if err := operatoragent.NewCredentials(root).ResetPassword(password); err != nil {
		return err
	}
	fmt.Println("the root password was reset; every agent session ends on its next request")
	return nil
}

func runLogout(root string) error {
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/logout", nil)
	if err != nil {
		return err
	}
	_ = os.Remove(filepath.Join(root, operatoragent.SessionFileName))
	return printResult(status, body)
}

func runBackend(root string, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: backend start [--closed] | restart [--closed] | stop | status")
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	switch args[0] {
	case "start":
		flags := flag.NewFlagSet("backend start", flag.ContinueOnError)
		flags.SetOutput(os.Stderr)
		closed := flags.Bool("closed", false, "do not bind the game listener")
		if err := flags.Parse(args[1:]); err != nil {
			return err
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backend/start", map[string]bool{"closed": *closed})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "restart":
		flags := flag.NewFlagSet("backend restart", flag.ContinueOnError)
		flags.SetOutput(os.Stderr)
		closed := flags.Bool("closed", false, "do not bind the game listener")
		if err := flags.Parse(args[1:]); err != nil {
			return err
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backend/restart", map[string]bool{"closed": *closed})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "stop":
		status, body, err := client.request(http.MethodPost, "/agent/v1/backend/stop", nil)
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "status":
		status, body, err := client.request(http.MethodGet, "/agent/v1/backend/status", nil)
		if err != nil {
			return err
		}
		return printResult(status, body)
	default:
		return fmt.Errorf("unknown backend command %q", args[0])
	}
}

func runCommand(root string, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: cmd <module.command> --reason <text> [--key <key>] [json payload]")
	}
	name := args[0]
	flags := flag.NewFlagSet("cmd", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	reason := flags.String("reason", "", "why the operator runs the command")
	semanticKey := flags.String("key", "", "idempotency key; a new one is chosen when omitted")
	if err := flags.Parse(args[1:]); err != nil {
		return err
	}
	if *reason == "" {
		return errors.New("--reason is required")
	}
	if err := defaultSemanticKey(semanticKey); err != nil {
		return err
	}
	payload := "{}"
	if flags.NArg() > 0 {
		payload = flags.Arg(0)
	}
	if !json.Valid([]byte(payload)) {
		return errors.New("the payload is not JSON")
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/commands/"+name, map[string]any{
		"reason": *reason, "semantic_key": *semanticKey, "payload": json.RawMessage(payload),
	})
	if err != nil {
		return err
	}
	return printResult(status, body)
}

func runBackup(root string, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: backup snapshot|list|prune|pin|unpin|restore|update-backend")
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	switch args[0] {
	case "snapshot":
		flags := flag.NewFlagSet("backup snapshot", flag.ContinueOnError)
		flags.SetOutput(os.Stderr)
		kind := flags.String("kind", operatoragent.BackupKindManual, "manual, safety, pre-update or pre-delete")
		reason := flags.String("reason", "", "why the snapshot is taken")
		name := flags.String("name", "", "snapshot name, 1-80 printable characters")
		pin := flags.Bool("pin", false, "keep this snapshot: pinned snapshots are never pruned")
		if err := flags.Parse(args[1:]); err != nil {
			return err
		}
		if *reason == "" {
			return errors.New("--reason is required")
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backup/snapshot", map[string]any{"kind": *kind, "reason": *reason, "name": *name, "pin": *pin})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "list":
		status, body, err := client.request(http.MethodGet, "/agent/v1/backup/list", nil)
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "prune":
		reason, err := backupReasonFlag(args[1:])
		if err != nil {
			return err
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backup/prune", map[string]string{"reason": reason})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "pin":
		if len(args) < 2 {
			return errors.New("usage: backup pin <id> --name <text>")
		}
		name, err := backupNameFlag(args[2:])
		if err != nil {
			return err
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backup/pin", map[string]string{"id": args[1], "name": name})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "unpin":
		if len(args) < 2 {
			return errors.New("usage: backup unpin <id>")
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backup/unpin", map[string]string{"id": args[1]})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "restore":
		if len(args) < 2 {
			return errors.New("usage: backup restore <id> --reason <text>")
		}
		reason, err := backupReasonFlag(args[2:])
		if err != nil {
			return err
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backup/restore", map[string]string{"id": args[1], "reason": reason})
		if err != nil {
			return err
		}
		return printResult(status, body)
	case "update-backend":
		reason, err := backupReasonFlag(args[1:])
		if err != nil {
			return err
		}
		status, body, err := client.request(http.MethodPost, "/agent/v1/backup/update-backend", map[string]string{"reason": reason})
		if err != nil {
			return err
		}
		return printResult(status, body)
	default:
		return fmt.Errorf("unknown backup command %q", args[0])
	}
}

func backupNameFlag(args []string) (string, error) {
	flags := flag.NewFlagSet("backup name", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	name := flags.String("name", "", "snapshot name, 1-80 printable characters")
	if err := flags.Parse(args); err != nil {
		return "", err
	}
	if *name == "" {
		return "", errors.New("--name is required")
	}
	return *name, nil
}

func backupReasonFlag(args []string) (string, error) {
	flags := flag.NewFlagSet("backup reason", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	reason := flags.String("reason", "", "why the operator runs the backup command")
	if err := flags.Parse(args); err != nil {
		return "", err
	}
	if *reason == "" {
		return "", errors.New("--reason is required")
	}
	return *reason, nil
}

func runRead(root string, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: read <module.read> [k=v ...]")
	}
	values := url.Values{}
	for _, argument := range args[1:] {
		key, value, found := strings.Cut(argument, "=")
		if !found {
			return fmt.Errorf("read parameters are k=v, got %q", argument)
		}
		values.Add(key, value)
	}
	path := "/agent/v1/reads/" + args[0]
	if encoded := values.Encode(); encoded != "" {
		path += "?" + encoded
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodGet, path, nil)
	if err != nil {
		return err
	}
	return printResult(status, body)
}

func runOTA(root string, args []string) error {
	if len(args) == 0 {
		return errors.New("usage: ota build|publish|withdraw <version> --reason <text> [--key <key>]")
	}
	switch args[0] {
	case "build":
		return runOTABuild(root, args[1:])
	case "publish", "withdraw":
		return runOTAMaintenance(root, args[0], args[1:])
	default:
		return fmt.Errorf("unknown ota command %q", args[0])
	}
}

func runOTAMaintenance(root, action string, args []string) error {
	if len(args) < 1 {
		return errors.New("usage: ota publish|withdraw <version> --reason <text> [--key <key>]")
	}
	version := args[0]
	flags := flag.NewFlagSet("ota "+action, flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	reason := flags.String("reason", "", "why the operator runs the maintenance window")
	semanticKey := flags.String("key", "", "idempotency key; a new one is chosen when omitted")
	if err := flags.Parse(args[1:]); err != nil {
		return err
	}
	if *reason == "" {
		return errors.New("--reason is required")
	}
	if err := defaultSemanticKey(semanticKey); err != nil {
		return err
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/ota/"+action, map[string]string{
		"version": version, "reason": *reason, "semantic_key": *semanticKey,
	})
	if err != nil {
		return err
	}
	return printResult(status, body)
}

// runOTABuild starts the long operation and, unless --no-wait, polls op status
// until it finishes (I11A_1_PLAN "L4c decisions").
func runOTABuild(root string, args []string) error {
	flags := flag.NewFlagSet("ota build", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	lane := flags.String("lane", "", "code, assets or catalog")
	version := flags.String("version", "", "release number")
	rollback := flags.Bool("rollback", false, "allow a number below the lane's active release")
	lazyRefresh := flags.Bool("lazy-refresh", false, "rewrite lazyFile.json from the active assets release (code lane)")
	noWait := flags.Bool("no-wait", false, "return as soon as the operation starts")
	timeout := flags.Duration("timeout", defaultBuildPollTimeout, "how long to poll the operation")
	if err := flags.Parse(args); err != nil {
		return err
	}
	if *lane == "" || *version == "" {
		return errors.New("--lane and --version are required")
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodPost, "/agent/v1/ota/build", map[string]any{
		"lane": *lane, "version": *version, "rollback": *rollback, "lazy_refresh": *lazyRefresh,
	})
	if err != nil {
		return err
	}
	if status != http.StatusAccepted {
		return printResult(status, body)
	}
	var started struct {
		OperationID string `json:"operation_id"`
	}
	if err := json.Unmarshal(body, &started); err != nil || started.OperationID == "" {
		return errors.New("the agent reply carried no operation id")
	}
	fmt.Println(strings.TrimRight(string(body), "\n"))
	if *noWait {
		return nil
	}
	return waitForOperation(client, started.OperationID, *timeout)
}

const (
	defaultBuildPollTimeout  = 3 * time.Hour
	operationPollInterval    = 500 * time.Millisecond
	operationNotFoundRetries = 5
)

// waitForOperation polls until the operation finishes, giving a bounded time and
// retrying a not-found answer a few times (L4f fixes 5 and 6).
func waitForOperation(client *agentClient, id string, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	notFound := 0
	for {
		if time.Now().After(deadline) {
			return fmt.Errorf("operation %s did not finish within %s", id, timeout)
		}
		status, body, err := client.request(http.MethodGet, "/agent/v1/ops/"+id, nil)
		if err != nil {
			return err
		}
		if status == http.StatusNotFound && notFound < operationNotFoundRetries {
			notFound++
			time.Sleep(operationPollInterval)
			continue
		}
		notFound = 0
		if status != http.StatusOK {
			return printResult(status, body)
		}
		var operation operatoragent.Operation
		if err := json.Unmarshal(body, &operation); err != nil {
			return err
		}
		switch operation.State {
		case operatoragent.OperationDone:
			fmt.Println(strings.TrimRight(string(body), "\n"))
			return nil
		case operatoragent.OperationFailed:
			fmt.Println(strings.TrimRight(string(body), "\n"))
			if operation.FailedStep != "" {
				return fmt.Errorf("ota build failed at %s: %s", operation.FailedStep, operation.Error)
			}
			return errors.New("ota build failed")
		}
		time.Sleep(operationPollInterval)
	}
}

func runOperation(root string, args []string) error {
	if len(args) != 2 || args[0] != "status" {
		return errors.New("usage: op status <id>")
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodGet, "/agent/v1/ops/"+args[1], nil)
	if err != nil {
		return err
	}
	return printResult(status, body)
}

// runModules prints the merged registry the GUI builds its tabs from: table by
// default, the raw agent reply with --json.
func runModules(root string, args []string) error {
	flags := flag.NewFlagSet("modules", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	asJSON := flags.Bool("json", false, "print the raw agent reply")
	if err := flags.Parse(args); err != nil {
		return err
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodGet, "/agent/v1/modules", nil)
	if err != nil {
		return err
	}
	if status != http.StatusOK {
		return printResult(status, body)
	}
	if *asJSON {
		fmt.Println(strings.TrimRight(string(body), "\n"))
		return nil
	}
	var reply operatoragent.AgentModules
	if err := json.Unmarshal(body, &reply); err != nil {
		return err
	}
	printModuleTable(os.Stdout, reply)
	if reply.BackendError != "" {
		fmt.Fprintln(os.Stderr, reply.BackendError)
	}
	return nil
}

func printModuleTable(output io.Writer, reply operatoragent.AgentModules) {
	writer := tabwriter.NewWriter(output, 0, 0, 2, ' ', 0)
	fmt.Fprintln(writer, "MODULE\tKIND\tNAME\tCLASS\tROUTE\tHELP")
	for _, module := range reply.Modules {
		kind := "command"
		if module.Planned != "" {
			kind = "planned"
		}
		if len(module.Commands) == 0 && len(module.Reads) == 0 {
			fmt.Fprintf(writer, "%s\t%s\t-\t-\t-\t%s (%s)\n", module.ID, kind, module.Title, module.Planned)
			continue
		}
		for _, command := range module.Commands {
			route := command.Route
			if route == "" {
				route = "backend"
			}
			fmt.Fprintf(writer, "%s\t%s\t%s\t%s\t%s\t%s\n", module.ID, kind, command.Name, command.Class, route, command.Help)
		}
		for _, read := range module.Reads {
			fmt.Fprintf(writer, "%s\t%s\t%s\t-\tbackend\t%s\n", module.ID, kind, read.Name, read.Help)
		}
	}
	writer.Flush()
}

func runLog(root string, args []string) error {
	if len(args) == 0 || args[0] != "tail" {
		return errors.New("usage: log tail [-n N]")
	}
	flags := flag.NewFlagSet("log tail", flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	count := flags.Int("n", 50, "number of lines")
	if err := flags.Parse(args[1:]); err != nil {
		return err
	}
	client, err := newAgentClient(root, true)
	if err != nil {
		return err
	}
	status, body, err := client.request(http.MethodGet, fmt.Sprintf("/agent/v1/log/tail?n=%d", *count), nil)
	if err != nil {
		return err
	}
	return printResult(status, body)
}

// defaultSemanticKey prints the key so the operator can resend the same
// command (I11A_1_PLAN "Agent decisions").
func defaultSemanticKey(key *string) error {
	if *key != "" {
		return nil
	}
	generated, err := operatoragent.NewToken()
	if err != nil {
		return err
	}
	*key = generated
	fmt.Fprintf(os.Stderr, "semantic_key=%s\n", generated)
	return nil
}
