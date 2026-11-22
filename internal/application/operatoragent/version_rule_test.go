package operatoragent

import (
	"errors"
	"testing"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

func statusWith(code string, built ...string) otaStatusReply {
	var status otaStatusReply
	if code != "" {
		text := code
		status.Active.Code = &text
	}
	for _, version := range built {
		status.Built = append(status.Built, struct {
			Version string `json:"version"`
			Lane    string `json:"lane"`
		}{Version: version, Lane: string(domain.LaneCode)})
	}
	return status
}

func TestResolveBuildVersionIncrementsOnlyTheLastComponent(t *testing.T) {
	status := statusWith("", "1.631.3")
	version, err := resolveBuildVersion(status, domain.LaneCode, "", false)
	if err != nil || version.String() != "1.631.4" {
		t.Fatalf("next = %v err=%v", version, err)
	}
	if _, err := resolveBuildVersion(status, domain.LaneCode, "1.631.4", false); err != nil {
		t.Fatalf("the computed next was refused: %v", err)
	}
	for _, skipped := range []string{"1.634.2", "2.631.2", "1.631.5"} {
		_, err := resolveBuildVersion(status, domain.LaneCode, skipped, false)
		var refusal *Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionNotNext {
			t.Fatalf("%s was accepted or refused with %v", skipped, err)
		}
	}
}

func TestResolveBuildVersionUsesActiveAndBuiltReleases(t *testing.T) {
	status := statusWith("1.631.3")
	version, err := resolveBuildVersion(status, domain.LaneCode, "", false)
	if err != nil || version.String() != "1.631.4" {
		t.Fatalf("next = %v err=%v", version, err)
	}
}

func TestResolveBuildVersionRollbackNamesItsOwnLowerNumber(t *testing.T) {
	status := statusWith("", "1.631.3")
	version, err := resolveBuildVersion(status, domain.LaneCode, "1.631.1", true)
	if err != nil || version.String() != "1.631.1" {
		t.Fatalf("rollback = %v err=%v", version, err)
	}
	for _, bad := range []string{"", "1.631.3", "1.631.4"} {
		if _, err := resolveBuildVersion(status, domain.LaneCode, bad, true); err == nil {
			t.Fatalf("rollback %q was accepted", bad)
		}
	}
}

func TestResolveBuildVersionNeedsABaselineForAnAutomaticNumber(t *testing.T) {
	if _, err := resolveBuildVersion(otaStatusReply{}, domain.LaneCode, "", false); err == nil {
		t.Fatal("an empty lane computed a version")
	}
	version, err := resolveBuildVersion(otaStatusReply{}, domain.LaneCode, "1.631.1", false)
	if err != nil || version.String() != "1.631.1" {
		t.Fatalf("the first version was refused: %v err=%v", version, err)
	}
}
