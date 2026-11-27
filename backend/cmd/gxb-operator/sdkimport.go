package main

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"gxb.local/backend/v2/internal/application/operatoragent"
)

// The one-time SDK login import (G51F F4). The agent never opens the database
// itself (I11A_ARCHITECTURE_V1 section 1): it starts the existing
// gxb-player-data tool, which applies the file through the identity owner and
// prints counts only.
const playerDataBinaryEnvironment = "GXB_PLAYER_DATA_BINARY"

func runSDKImport(root string, args []string) error {
	if len(args) != 1 {
		return errors.New("usage: sdk-import <accounts.json>")
	}
	path := args[0]
	if info, err := os.Stat(path); err != nil || info.IsDir() {
		return fmt.Errorf("accounts file %q is not readable", path)
	}
	binary, err := playerDataBinary()
	if err != nil {
		return err
	}
	dsn, err := sdkImportDSN(root)
	if err != nil {
		return err
	}
	command := exec.CommandContext(context.Background(), binary, "-mode", "sdk-import", "-in", path)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	command.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+dsn)
	if err := command.Run(); err != nil {
		return fmt.Errorf("sdk import: %w", err)
	}
	return nil
}

func playerDataBinary() (string, error) {
	if configured := strings.TrimSpace(os.Getenv(playerDataBinaryEnvironment)); configured != "" {
		return configured, nil
	}
	if path, err := exec.LookPath("gxb-player-data"); err == nil {
		return path, nil
	}
	executable, err := os.Executable()
	if err != nil {
		return "", err
	}
	candidate := filepath.Join(filepath.Dir(executable), "gxb-player-data")
	if info, err := os.Stat(candidate); err == nil && !info.IsDir() {
		return candidate, nil
	}
	return "", fmt.Errorf("gxb-player-data was not found; set %s", playerDataBinaryEnvironment)
}

func sdkImportDSN(root string) (string, error) {
	if dsn := strings.TrimSpace(os.Getenv("GXB_POSTGRES_DSN")); dsn != "" {
		return dsn, nil
	}
	config, err := operatoragent.LoadConfig(root)
	if err != nil {
		return "", err
	}
	dsn, err := operatoragent.ReadEnvValue(config.Backend.EnvFile, "GXB_POSTGRES_DSN")
	if err != nil {
		return "", err
	}
	if strings.TrimSpace(dsn) == "" {
		return "", errors.New("GXB_POSTGRES_DSN is not set in the environment or the backend env file")
	}
	return dsn, nil
}
