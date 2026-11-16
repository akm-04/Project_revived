package main

import (
	"flag"
	"fmt"
	"io"
	"strings"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

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
