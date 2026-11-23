package operatoragent

import (
	"os"
	"strings"
	"testing"
)

func TestCLIUsageTextListsEveryCommandWithASummary(t *testing.T) {
	text := CLIUsageText()
	if !strings.HasPrefix(text, "usage:\n") {
		t.Fatalf("usage text = %q", text)
	}
	for _, command := range CLICommands() {
		if command.Summary == "" {
			t.Fatalf("%q has no summary", command.Usage)
		}
		if !strings.Contains(text, command.Usage) {
			t.Fatalf("usage text lacks %q:\n%s", command.Usage, text)
		}
	}
}

func TestCLIHelpCarriesTheBannerAndTheSameCommands(t *testing.T) {
	help := CLIHelp()
	if help.Banner != CLIUsageBanner {
		t.Fatalf("banner = %q", help.Banner)
	}
	if help.Usage != CLIUsageText() {
		t.Fatal("the help usage text differs from CLIUsageText")
	}
	if len(help.Commands) != len(CLICommands()) {
		t.Fatalf("commands = %d", len(help.Commands))
	}
}

func TestTerminalBannerStartsWithTheCLIHint(t *testing.T) {
	banner := TerminalBanner()
	if !strings.HasPrefix(banner, CLIUsageBanner+"\r\n") {
		t.Fatalf("banner = %q", banner)
	}
	if !strings.Contains(banner, "usage:\r\n") {
		t.Fatal("the banner does not carry the usage text")
	}
	if strings.Contains(strings.ReplaceAll(banner, "\r\n", ""), "\n") {
		t.Fatal("the banner has a bare newline a terminal would not return")
	}
}

func TestTerminalEnvironmentWithCLIPutsTheBinaryFolderFirstAndPassesTheRoot(t *testing.T) {
	binaries := t.TempDir()
	environment := TerminalEnvironmentWithCLI([]string{"PATH=/usr/bin", "HOME=/home/operator", "GXB_API_KEY=secret"}, binaries, "/srv/agent")
	values := map[string]string{}
	for _, entry := range environment {
		name, value, _ := strings.Cut(entry, "=")
		values[name] = value
	}
	wantPath := binaries + string(os.PathListSeparator) + "/usr/bin"
	if values["PATH"] != wantPath {
		t.Fatalf("PATH = %q, want %q", values["PATH"], wantPath)
	}
	if values["GXB_OPERATOR_ROOT"] != "/srv/agent" {
		t.Fatalf("GXB_OPERATOR_ROOT = %q", values["GXB_OPERATOR_ROOT"])
	}
	if _, present := values["GXB_API_KEY"]; present {
		t.Fatal("a secret reached the terminal environment")
	}
}
