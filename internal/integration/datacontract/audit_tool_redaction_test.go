//go:build postgres

package datacontract_test

import (
	"bytes"
	"os"
	"os/exec"
	"testing"
)

func TestAuditA061FailedToolRedactsCredentials(t *testing.T) {
	if os.Getenv("GXB_A061_TOOL_CHILD") == "1" {
		database := "postgres://audit:" + os.Getenv("GXB_A061_EPHEMERAL_TOKEN") + "@invalid/audit_probe"
		payloadDigestRunTool(t, "false", database)
		return
	}
	token := payloadDigestUUID(t).String()
	command := exec.Command(os.Args[0], "-test.run=^TestAuditA061FailedToolRedactsCredentials$")
	command.Env = append(os.Environ(), "GXB_A061_TOOL_CHILD=1", "GXB_A061_EPHEMERAL_TOKEN="+token)
	output, err := command.CombinedOutput()
	if err == nil {
		t.Fatal("failing helper unexpectedly succeeded")
	}
	if bytes.Contains(output, []byte(token)) {
		t.Fatal("tool failure log contains the DSN credential (synthetic token withheld)")
	}
}
