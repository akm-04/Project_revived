package operatoragent

import (
	"fmt"
	"strings"
)

// CLIUsageBanner is the first line the Terminal page prints before the prompt.
const CLIUsageBanner = "Operator CLI: type gxb-operator help"

// CLICommand is one line of the operator CLI help. Usage is the printed shape,
// Prefix is the text the Terminal page types when its row is chosen, and
// Summary is the one-line description.
type CLICommand struct {
	Usage   string `json:"usage"`
	Prefix  string `json:"prefix"`
	Summary string `json:"summary"`
}

// CLIUsage is the agent.cli.usage reply and the source of the CLI help text,
// the Terminal banner and the Terminal page's Commands panel.
type CLIUsage struct {
	Banner   string       `json:"banner"`
	Usage    string       `json:"usage"`
	Commands []CLICommand `json:"commands"`
}

var cliCommands = []CLICommand{
	{Usage: "gxb-operator help", Prefix: "gxb-operator help", Summary: "Show this help."},
	{Usage: "gxb-operator [--root DIR] agent", Prefix: "gxb-operator --root ", Summary: "Run the operator agent; --root or GXB_OPERATOR_ROOT names its folder."},
	{Usage: "gxb-operator setup", Prefix: "gxb-operator setup", Summary: "Set the root password of a new agent root."},
	{Usage: "gxb-operator login", Prefix: "gxb-operator login", Summary: "Log in and store the session token in cli.session."},
	{Usage: "gxb-operator logout", Prefix: "gxb-operator logout", Summary: "End the session and remove cli.session."},
	{Usage: "gxb-operator reset-password", Prefix: "gxb-operator reset-password", Summary: "Reset a forgotten root password offline."},
	{Usage: "gxb-operator backend start [--closed]", Prefix: "gxb-operator backend ", Summary: "Start the backend; --closed skips the game listener."},
	{Usage: "gxb-operator backend restart [--closed]", Prefix: "gxb-operator backend ", Summary: "Stop and start the backend."},
	{Usage: "gxb-operator backend stop", Prefix: "gxb-operator backend ", Summary: "Stop the backend process."},
	{Usage: "gxb-operator backend status", Prefix: "gxb-operator backend ", Summary: "Report whether the backend runs."},
	{Usage: "gxb-operator cmd <module.command> --reason <text> [--key <key>] [json payload]", Prefix: "gxb-operator cmd ", Summary: "Run one module command with a reason."},
	{Usage: "gxb-operator read <module.read> [k=v ...]", Prefix: "gxb-operator read ", Summary: "Run one module read with key=value parameters."},
	{Usage: "gxb-operator ota build --lane <code|assets|catalog> --version <v> [--rollback] [--no-wait]", Prefix: "gxb-operator ota ", Summary: "Build a release offline."},
	{Usage: "gxb-operator ota publish <version> --reason <text> [--key <key>]", Prefix: "gxb-operator ota ", Summary: "Publish a release in a maintenance window."},
	{Usage: "gxb-operator ota withdraw <version> --reason <text> [--key <key>]", Prefix: "gxb-operator ota ", Summary: "Withdraw an active release."},
	{Usage: "gxb-operator backup snapshot [--kind manual|safety|pre-update|pre-delete] --reason <text>", Prefix: "gxb-operator backup ", Summary: "Take a database snapshot."},
	{Usage: "gxb-operator backup list", Prefix: "gxb-operator backup ", Summary: "List snapshots newest first."},
	{Usage: "gxb-operator backup prune --reason <text>", Prefix: "gxb-operator backup ", Summary: "Delete all but the newest kept snapshots."},
	{Usage: "gxb-operator backup pin <id> --name <text>", Prefix: "gxb-operator backup ", Summary: "Name a snapshot and keep it out of every prune."},
	{Usage: "gxb-operator backup unpin <id>", Prefix: "gxb-operator backup ", Summary: "Return a pinned snapshot to normal pruning."},
	{Usage: "gxb-operator backup restore <id> --reason <text>", Prefix: "gxb-operator backup ", Summary: "Restore a snapshot."},
	{Usage: "gxb-operator backup update-backend --reason <text>", Prefix: "gxb-operator backup ", Summary: "Snapshot, stop, swap the binary and start."},
	{Usage: "gxb-operator op status <id>", Prefix: "gxb-operator op status ", Summary: "Show one long operation."},
	{Usage: "gxb-operator modules [--json]", Prefix: "gxb-operator modules", Summary: "List the command and read registry."},
	{Usage: "gxb-operator log tail [-n N]", Prefix: "gxb-operator log tail ", Summary: "Tail the agent tool log."},
	{Usage: "gxb-operator sdk-import <accounts.json>", Prefix: "gxb-operator sdk-import ", Summary: "Import stand-in accounts from a JSON file."},
}

// CLICommands returns a copy of the CLI command list.
func CLICommands() []CLICommand {
	commands := make([]CLICommand, len(cliCommands))
	copy(commands, cliCommands)
	return commands
}

// CLIUsageText renders the usage block the CLI prints and the Terminal shows;
// every caller reads this one function, so the text never drifts between them.
func CLIUsageText() string {
	var builder strings.Builder
	builder.WriteString("usage:\n")
	for _, command := range cliCommands {
		fmt.Fprintf(&builder, "  %-46s %s\n", command.Usage, command.Summary)
	}
	return builder.String()
}

// CLIHelp is the agent.cli.usage reply.
func CLIHelp() CLIUsage {
	return CLIUsage{Banner: CLIUsageBanner, Usage: CLIUsageText(), Commands: CLICommands()}
}
