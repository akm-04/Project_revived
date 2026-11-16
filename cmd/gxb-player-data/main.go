//go:build postgres && linux

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/playerdatastore"
	"gxb.local/backend/v2/internal/application/playerdata"
)

const defaultPlanPath = "docs/data/PLAYER_RESTORE_PLAN.json"

type refusal struct{ reason string }

func (r refusal) Error() string { return r.reason }

func main() {
	os.Exit(run(os.Args[1:], os.Stdout, os.Stderr))
}

func run(arguments []string, stdout, stderr io.Writer) int {
	flags := flag.NewFlagSet("gxb-player-data", flag.ContinueOnError)
	flags.SetOutput(stderr)
	mode := flags.String("mode", "plan", "plan|export|restore")
	planPath := flags.String("plan", defaultPlanPath, "generated player restore plan")
	player := flags.Int64("player", 0, "player id to export")
	out := flags.String("out", "", "output file (default standard output)")
	if err := flags.Parse(arguments); err != nil {
		return 2
	}
	switch *mode {
	case "plan":
		return printPlan(*planPath, stdout, stderr)
	case "export":
		return export(*planPath, *player, *out, stdout, stderr)
	case "restore":
		return report(stderr, refusal{"restore not built"})
	default:
		return report(stderr, refusal{fmt.Sprintf("unknown mode %q", *mode)})
	}
}

func printPlan(path string, stdout, stderr io.Writer) int {
	plan, _, err := playerdata.LoadPlan(path)
	if err != nil {
		return report(stderr, refusal{err.Error()})
	}
	raw, err := json.MarshalIndent(plan, "", " ")
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	if _, err := stdout.Write(append(raw, '\n')); err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	return 0
}

func export(planPath string, playerID int64, outputPath string, stdout, stderr io.Writer) int {
	if playerID <= 0 {
		return report(stderr, refusal{"export requires -player"})
	}
	plan, planDigest, err := playerdata.LoadPlan(planPath)
	if err != nil {
		return report(stderr, refusal{err.Error()})
	}
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	if dsn == "" {
		fmt.Fprintln(stderr, "GXB_POSTGRES_DSN required")
		return 1
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	defer pool.Close()

	service := playerdata.Service{Database: pool, Reader: playerdatastore.Store{}}
	document, err := service.Export(ctx, plan, planDigest, playerID, time.Now().UTC())
	if err != nil {
		if errors.Is(err, playerdata.ErrPlayerNotFound) || errors.Is(err, playerdata.ErrInvalidPlan) {
			return report(stderr, refusal{err.Error()})
		}
		fmt.Fprintln(stderr, err)
		return 1
	}
	var buffer bytes.Buffer
	if err := playerdata.Encode(&buffer, document); err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	if outputPath == "" {
		if _, err := stdout.Write(buffer.Bytes()); err != nil {
			fmt.Fprintln(stderr, err)
			return 1
		}
		return 0
	}
	if err := os.WriteFile(outputPath, buffer.Bytes(), 0o600); err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	return 0
}

func report(stderr io.Writer, err error) int {
	fmt.Fprintln(stderr, err)
	return 3
}
