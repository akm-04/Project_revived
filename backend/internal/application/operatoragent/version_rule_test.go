package operatoragent

import (
	"errors"
	"strings"
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
	if version, err := resolveBuildVersion(status, domain.LaneCode, "1.631.20", false); err != nil || version.String() != "1.631.20" {
		t.Fatalf("a typed jump ahead = %v err=%v", version, err)
	}
	for _, otherLine := range []string{"1.634.2", "2.631.2"} {
		_, err := resolveBuildVersion(status, domain.LaneCode, otherLine, false)
		var refusal *Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionNotNext {
			t.Fatalf("%s was accepted or refused with %v", otherLine, err)
		}
	}
}

func TestResolveBuildVersionKeepsTheLaneLineOnEveryPath(t *testing.T) {
	activeLine := "1.631.7"
	withActive := otaStatusReply{}
	withActive.Active.Code = &activeLine
	for _, acknowledgement := range []bool{false, true} {
		for _, other := range []string{"1.600.5", "1.632.1", "2.631.1"} {
			_, err := resolveBuildVersion(withActive, domain.LaneCode, other, acknowledgement)
			var refusal *Refusal
			if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionNotNext {
				t.Fatalf("active %s, typed %s acknowledgement=%t: %v", activeLine, other, acknowledgement, err)
			}
			if !strings.Contains(refusal.Message, "keep 1.631 and change only the last number") {
				t.Fatalf("refusal does not name the line: %q", refusal.Message)
			}
		}
	}
	noActive := statusWith("", "1.631.3")
	for _, acknowledgement := range []bool{false, true} {
		for _, other := range []string{"1.600.1", "1.632.1"} {
			_, err := resolveBuildVersion(noActive, domain.LaneCode, other, acknowledgement)
			var refusal *Refusal
			if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionNotNext {
				t.Fatalf("built line, typed %s acknowledgement=%t: %v", other, acknowledgement, err)
			}
		}
	}
	if version, err := resolveBuildVersion(withActive, domain.LaneCode, "1.631.1", true); err != nil || version.String() != "1.631.1" {
		t.Fatalf("same-line rollback = %v err=%v", version, err)
	}
	if version, err := resolveBuildVersion(withActive, domain.LaneCode, "1.631.20", false); err != nil || version.String() != "1.631.20" {
		t.Fatalf("same-line forward = %v err=%v", version, err)
	}
}

func TestResolveBuildVersionRefusesTheLastIntegerOverflow(t *testing.T) {
	status := statusWith("", "1.631.9223372036854775807")
	_, err := resolveBuildVersion(status, domain.LaneCode, "", false)
	var refusal *Refusal
	if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionInvalid {
		t.Fatalf("auto-next at the maximum integer: %v", err)
	}
	version, err := resolveBuildVersion(status, domain.LaneCode, "1.631.9223372036854775807", false)
	if err != nil || version.String() != "1.631.9223372036854775807" {
		t.Fatalf("typed maximum = %v err=%v", version, err)
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

func TestResolveBuildVersionRollbackNeedsTheAcknowledgement(t *testing.T) {
	activeText := "1.631.7"
	status := otaStatusReply{}
	status.Active.Code = &activeText
	for _, lower := range []string{"1.631.6", "1.631.0"} {
		_, err := resolveBuildVersion(status, domain.LaneCode, lower, false)
		var refusal *Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeBuildRollbackRequired {
			t.Fatalf("%s without the acknowledgement: %v", lower, err)
		}
		if !strings.Contains(refusal.Message, "clear the app's data") || !strings.Contains(refusal.Message, "reinstall") {
			t.Fatalf("%s refusal does not say clients must clear data: %q", lower, refusal.Message)
		}
		version, err := resolveBuildVersion(status, domain.LaneCode, lower, true)
		if err != nil || version.String() != lower {
			t.Fatalf("acknowledged rollback %s = %v err=%v", lower, version, err)
		}
	}
}

func TestResolveBuildVersionRefusesTheActiveNumber(t *testing.T) {
	activeText := "1.631.7"
	status := otaStatusReply{}
	status.Active.Code = &activeText
	for _, acknowledgement := range []bool{false, true} {
		_, err := resolveBuildVersion(status, domain.LaneCode, "1.631.7", acknowledgement)
		var refusal *Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionNotNext {
			t.Fatalf("the active number with acknowledgement=%t: %v", acknowledgement, err)
		}
		if !strings.Contains(refusal.Message, "already active") {
			t.Fatalf("refusal does not name the active number: %q", refusal.Message)
		}
	}
}

func TestResolveBuildVersionRollbackAcknowledgementNeedsANumberBelowActive(t *testing.T) {
	status := statusWith("1.631.7", "1.631.9")
	for _, above := range []string{"1.631.7", "1.631.8", "1.631.9"} {
		if _, err := resolveBuildVersion(status, domain.LaneCode, above, true); err == nil {
			t.Fatalf("rollback acknowledgement accepted %s, which is not below the active release", above)
		}
	}
}

func TestResolveBuildVersionRefusesAFormatTheClientCannotCompare(t *testing.T) {
	for _, bad := range []string{"1.631", "1.631.2.3", "v1.631.2", "1.631.x", " 1.631.2"} {
		_, err := resolveBuildVersion(otaStatusReply{}, domain.LaneCode, bad, false)
		var refusal *Refusal
		if !errors.As(err, &refusal) || refusal.Code != CodeBuildVersionInvalid {
			t.Fatalf("%q was not refused as uncomparable: %v", bad, err)
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
