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
	"path/filepath"
	"strings"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/identitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/playerdatastore"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	"gxb.local/backend/v2/internal/application/playerdata"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
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
	mode := flags.String("mode", "plan", "plan|export|restore|sdk-import")
	planPath := flags.String("plan", defaultPlanPath, "generated player restore plan")
	player := flags.Int64("player", 0, "player id to export or restore")
	out := flags.String("out", "", "export output file (default standard output)")
	in := flags.String("in", "", "export file to restore")
	if err := flags.Parse(arguments); err != nil {
		return 2
	}
	switch *mode {
	case "plan":
		return printPlan(*planPath, stdout, stderr)
	case "export":
		return export(*planPath, *player, *out, stdout, stderr)
	case "restore":
		return restore(*planPath, *in, *player, stdout, stderr)
	case "sdk-import":
		return sdkImport(*in, stdout, stderr)
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

func restore(planPath, inputPath string, playerID int64, stdout, stderr io.Writer) int {
	if playerID <= 0 {
		return report(stderr, refusal{"restore requires -player"})
	}
	if inputPath == "" {
		return report(stderr, refusal{"restore requires -in"})
	}
	plan, planDigest, err := playerdata.LoadPlan(planPath)
	if err != nil {
		return report(stderr, refusal{err.Error()})
	}
	file, err := os.Open(inputPath)
	if err != nil {
		return report(stderr, refusal{err.Error()})
	}
	document, err := playerdata.Decode(file)
	_ = file.Close()
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

	var blobs playerdata.MediaBlobs
	if root := os.Getenv("GXB_PROFILE_MEDIA_ROOT"); root != "" {
		blobs = localMediaBlobs{root: root}
	}
	service := playerdata.RestoreService{Database: pool, Store: playerdatastore.Store{}, Roots: i4store.PlayerRootLocker{}, Blobs: blobs}
	result, err := service.Restore(ctx, plan, planDigest, playerID, document, time.Now().UTC())
	if err != nil {
		if errors.Is(err, playerdata.ErrRestoreRefused) || errors.Is(err, playerdata.ErrInvalidExport) || errors.Is(err, playerdata.ErrInvalidPlan) {
			return report(stderr, refusal{err.Error()})
		}
		fmt.Fprintln(stderr, err)
		return 1
	}
	raw, err := json.Marshal(result)
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

// localMediaBlobs checks the ProfileAssetStore layout the profile media
// maintenance command owns; only a well-formed blob key can reach the join.
type localMediaBlobs struct{ root string }

func (blobs localMediaBlobs) BlobExists(key string) (bool, error) {
	if !validBlobKey(key) {
		return false, nil
	}
	info, err := os.Stat(filepath.Join(blobs.root, "blobs", key))
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return info.Mode().IsRegular(), nil
}

func validBlobKey(key string) bool {
	const digestLength = 64
	if len(key) != digestLength+len(".png") || !strings.HasSuffix(key, ".png") {
		return false
	}
	for _, character := range key[:digestLength] {
		if (character < '0' || character > '9') && (character < 'a' || character > 'f') {
			return false
		}
	}
	return true
}

// sdkImport applies the login stand-in's accounts file (G51F F4) through the
// identity owner and prints counts only.
func sdkImport(inputPath string, stdout, stderr io.Writer) int {
	if inputPath == "" {
		return report(stderr, refusal{"sdk-import requires -in"})
	}
	file, err := os.Open(inputPath)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	defer file.Close()
	input, err := appidentity.DecodeSDKImport(file)
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
	importer := appidentity.SDKImporter{Runner: tx.Runner{DB: pool}, Store: identitystore.Store{}, Operations: operation.Factory{Clock: clock.System{}}}
	result, err := importer.Import(ctx, input)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 1
	}
	raw, err := json.Marshal(result)
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

func report(stderr io.Writer, err error) int {
	fmt.Fprintln(stderr, err)
	return 3
}
