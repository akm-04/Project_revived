package main

import (
	"flag"
	"fmt"
	"io"
	"strings"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

type restoreEpochArgs struct {
	Action   string
	Backup   string
	Epoch    int64
	Operator string
	Note     string
}

func parseRestoreEpochArgs(arguments []string) (restoreEpochArgs, error) {
	if len(arguments) == 0 {
		return restoreEpochArgs{}, fmt.Errorf("restore-epoch requires an action: begin or reconcile")
	}
	switch arguments[0] {
	case "begin":
		return parseRestoreEpochBeginArgs(arguments[1:])
	case "reconcile":
		return parseRestoreEpochReconcileArgs(arguments[1:])
	default:
		return restoreEpochArgs{}, fmt.Errorf("unknown restore-epoch action %q: use begin or reconcile", arguments[0])
	}
}

func parseRestoreEpochBeginArgs(arguments []string) (restoreEpochArgs, error) {
	flags := flag.NewFlagSet("restore-epoch begin", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	backup := flags.String("backup", "", "backup label")
	operator := flags.String("operator", "", "operator name")
	if err := flags.Parse(arguments); err != nil {
		return restoreEpochArgs{}, err
	}
	if flags.NArg() != 0 {
		return restoreEpochArgs{}, fmt.Errorf("unexpected arguments: %s", strings.Join(flags.Args(), " "))
	}
	trimmedBackup := strings.TrimSpace(*backup)
	trimmedOperator := strings.TrimSpace(*operator)
	if trimmedBackup == "" || trimmedOperator == "" {
		return restoreEpochArgs{}, fmt.Errorf("-backup and -operator are required")
	}
	return restoreEpochArgs{Action: "begin", Backup: trimmedBackup, Operator: trimmedOperator}, nil
}

func parseRestoreEpochReconcileArgs(arguments []string) (restoreEpochArgs, error) {
	flags := flag.NewFlagSet("restore-epoch reconcile", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	epoch := flags.Int64("epoch", 0, "restore epoch")
	operator := flags.String("operator", "", "operator name")
	note := flags.String("note", "", "reconciliation attestation")
	if err := flags.Parse(arguments); err != nil {
		return restoreEpochArgs{}, err
	}
	if flags.NArg() != 0 {
		return restoreEpochArgs{}, fmt.Errorf("unexpected arguments: %s", strings.Join(flags.Args(), " "))
	}
	trimmedOperator := strings.TrimSpace(*operator)
	trimmedNote := strings.TrimSpace(*note)
	if *epoch <= 0 || trimmedOperator == "" || trimmedNote == "" {
		return restoreEpochArgs{}, fmt.Errorf("-epoch, -operator and -note are required")
	}
	return restoreEpochArgs{Action: "reconcile", Epoch: *epoch, Operator: trimmedOperator, Note: trimmedNote}, nil
}

type revokeSessionArgs struct {
	Player   identity.PlayerID
	Session  identity.SessionID
	Operator string
	Reason   string
}

func parseRevokeSessionArgs(arguments []string) (revokeSessionArgs, error) {
	flags := flag.NewFlagSet("revoke-session", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	player := flags.Int64("player", 0, "player id")
	session := flags.String("session", "", "session uuid")
	operator := flags.String("operator", "", "operator name")
	reason := flags.String("reason", "", "reason code")
	if err := flags.Parse(arguments); err != nil {
		return revokeSessionArgs{}, err
	}
	if flags.NArg() != 0 {
		return revokeSessionArgs{}, fmt.Errorf("unexpected arguments: %s", strings.Join(flags.Args(), " "))
	}
	if (*player > 0) == (*session != "") {
		return revokeSessionArgs{}, fmt.Errorf("exactly one of -player or -session is required")
	}
	trimmedOperator := strings.TrimSpace(*operator)
	trimmedReason := strings.TrimSpace(*reason)
	if trimmedOperator == "" || trimmedReason == "" {
		return revokeSessionArgs{}, fmt.Errorf("-operator and -reason are required")
	}
	if *session == "" {
		if *player <= 0 {
			return revokeSessionArgs{}, fmt.Errorf("-player must be a positive player id")
		}
		return revokeSessionArgs{Player: identity.PlayerID(*player), Operator: trimmedOperator, Reason: trimmedReason}, nil
	}
	parsed, err := ids.ParseUUID(*session)
	if err != nil {
		return revokeSessionArgs{}, fmt.Errorf("-session must be a uuid: %w", err)
	}
	sessionID, err := identity.SessionIDFrom(parsed)
	if err != nil {
		return revokeSessionArgs{}, err
	}
	return revokeSessionArgs{Session: sessionID, Operator: trimmedOperator, Reason: trimmedReason}, nil
}
