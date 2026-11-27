package operatoragent

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
)

// serverBinaryNames are the five server binaries a release carries. gxb-operator
// is the agent itself, so a swap never replaces it.
var serverBinaryNames = []string{"gxb-api", "gxb-combat-worker", "gxb-worker", "gxb-realtime", "gxb-player-data"}

// releaseCommitPattern keeps BACKEND_COMMIT usable as one release folder name.
var releaseCommitPattern = regexp.MustCompile(`^[0-9A-Za-z][0-9A-Za-z._-]{0,63}$`)

// releaseFolder is a validated backend release: bin/, migrations/ and
// BACKEND_COMMIT, with the absolute paths agent.json points at.
type releaseFolder struct {
	Directory  string
	Binary     string
	Migrations string
	Commit     string
}

// ReleaseBuilder builds a source tree's server binaries into one bin folder;
// nil uses the configured Go toolchain. Tests inject it.
type ReleaseBuilder func(ctx context.Context, sourceDirectory, toolchainDirectory, binDirectory string) error

// serverBinaryFileName names one binary in a release's bin folder; a Windows
// release carries .exe files.
func serverBinaryFileName(name string) string {
	if runtime.GOOS == "windows" {
		return name + ".exe"
	}
	return name
}

// resolveRelease turns the -s folder into a release folder, building a source
// tree first when the folder has go.mod and no bin/.
func (service *BackupService) resolveRelease(ctx context.Context, folder string) (releaseFolder, error) {
	path := strings.TrimSpace(folder)
	if path == "" {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "the backend folder is required")
	}
	if !filepath.IsAbs(path) {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "the backend folder must be absolute")
	}
	info, err := os.Stat(path)
	if err != nil || !info.IsDir() {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "the backend folder is not a readable folder")
	}
	if !isDirectory(filepath.Join(path, "bin")) {
		if !isRegularFile(filepath.Join(path, "go.mod")) {
			return releaseFolder{}, Refuse(CodeBackupPathInvalid, "bin/gxb-api is missing and the folder has no go.mod, so it is neither a release folder nor a source tree")
		}
		return service.buildSourceRelease(ctx, path)
	}
	return validateReleaseFolder(path)
}

// validateReleaseFolder names the exact missing file of an incomplete release.
func validateReleaseFolder(directory string) (releaseFolder, error) {
	binDirectory := filepath.Join(directory, "bin")
	for _, name := range serverBinaryNames {
		fileName := serverBinaryFileName(name)
		if !isRegularFile(filepath.Join(binDirectory, fileName)) {
			return releaseFolder{}, Refuse(CodeBackupPathInvalid, "bin/"+fileName+" is missing")
		}
	}
	if !isDirectory(filepath.Join(directory, "migrations")) {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "migrations/ is missing")
	}
	commitContents, err := os.ReadFile(filepath.Join(directory, "BACKEND_COMMIT"))
	if err != nil {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "BACKEND_COMMIT is missing")
	}
	commit := strings.TrimSpace(string(commitContents))
	if commit == "" {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "BACKEND_COMMIT is empty")
	}
	binary := filepath.Join(binDirectory, serverBinaryFileName("gxb-api"))
	if err := ValidateBackendBinary(binary); err != nil {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, err.Error())
	}
	return releaseFolder{
		Directory:  directory,
		Binary:     binary,
		Migrations: filepath.Join(directory, "migrations"),
		Commit:     commit,
	}, nil
}

// buildSourceRelease builds a source tree into <agent root>/releases/<commit>/.
// An existing release folder is reused as-is, so no file ever replaces a
// running binary.
func (service *BackupService) buildSourceRelease(ctx context.Context, sourceDirectory string) (releaseFolder, error) {
	commitContents, err := os.ReadFile(filepath.Join(sourceDirectory, "BACKEND_COMMIT"))
	if err != nil {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "BACKEND_COMMIT is missing in the source tree")
	}
	commit := strings.TrimSpace(string(commitContents))
	if !releaseCommitPattern.MatchString(commit) {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "BACKEND_COMMIT is not a usable release name")
	}
	if !isDirectory(filepath.Join(sourceDirectory, "migrations")) {
		return releaseFolder{}, Refuse(CodeBackupPathInvalid, "migrations/ is missing in the source tree")
	}
	config, err := service.agentConfig()
	if err != nil {
		return releaseFolder{}, err
	}
	releasesDirectory := filepath.Join(service.agentRoot(), "releases")
	if err := os.MkdirAll(releasesDirectory, 0o700); err != nil {
		return releaseFolder{}, Temporarily(CodeBackupFailed, "the releases folder cannot be created")
	}
	releaseDirectory := filepath.Join(releasesDirectory, commit)
	if isDirectory(releaseDirectory) {
		return validateReleaseFolder(releaseDirectory)
	}
	staging, err := os.MkdirTemp(releasesDirectory, ".partial-")
	if err != nil {
		return releaseFolder{}, Temporarily(CodeBackupFailed, "the release staging folder cannot be created")
	}
	cleanup := true
	defer func() {
		if cleanup {
			_ = os.RemoveAll(staging)
		}
	}()
	binDirectory := filepath.Join(staging, "bin")
	if err := os.Mkdir(binDirectory, 0o700); err != nil {
		return releaseFolder{}, Temporarily(CodeBackupFailed, "the release bin folder cannot be created")
	}
	builder := service.BuildRelease
	if builder == nil {
		builder = buildReleaseBinaries
	}
	if err := builder(ctx, sourceDirectory, config.ToolchainPath, binDirectory); err != nil {
		return releaseFolder{}, Temporarily(CodeBackupFailed, "the release build failed: "+MaskString(err.Error()))
	}
	if err := copyDirectory(filepath.Join(sourceDirectory, "migrations"), filepath.Join(staging, "migrations")); err != nil {
		return releaseFolder{}, Temporarily(CodeBackupFailed, "the migrations folder cannot be copied: "+MaskString(err.Error()))
	}
	if err := copyFile(filepath.Join(sourceDirectory, "BACKEND_COMMIT"), filepath.Join(staging, "BACKEND_COMMIT")); err != nil {
		return releaseFolder{}, Temporarily(CodeBackupFailed, "BACKEND_COMMIT cannot be copied")
	}
	if err := os.Rename(staging, releaseDirectory); err != nil {
		if isDirectory(releaseDirectory) {
			return validateReleaseFolder(releaseDirectory)
		}
		return releaseFolder{}, Temporarily(CodeBackupFailed, "the release folder cannot be moved into place")
	}
	cleanup = false
	return validateReleaseFolder(releaseDirectory)
}

// buildReleaseBinaries builds the five server binaries with the configured Go
// toolchain and the postgres,river tags.
func buildReleaseBinaries(ctx context.Context, sourceDirectory, toolchainDirectory, binDirectory string) error {
	goPath, err := resolveGoExecutable(toolchainDirectory)
	if err != nil {
		return err
	}
	for _, name := range serverBinaryNames {
		output := filepath.Join(binDirectory, serverBinaryFileName(name))
		command := exec.CommandContext(ctx, goPath, "build", "-tags", "postgres,river", "-o", output, "./cmd/"+name)
		command.Dir = sourceDirectory
		var stderr bytes.Buffer
		command.Stderr = &stderr
		if err := command.Run(); err != nil {
			return fmt.Errorf("build %s: %w: %s", name, err, strings.TrimSpace(stderr.String()))
		}
	}
	return nil
}

// resolveGoExecutable finds go in the configured tools folder, else on PATH.
func resolveGoExecutable(toolchainDirectory string) (string, error) {
	name := "go"
	if runtime.GOOS == "windows" {
		name = "go.exe"
	}
	if toolchainDirectory == "" {
		path, err := exec.LookPath(name)
		if err != nil {
			return "", errors.New("go is not on PATH; set toolchain_path or install Go")
		}
		return path, nil
	}
	path := filepath.Join(toolchainDirectory, name)
	if !isRegularFile(path) {
		return "", fmt.Errorf("%s is missing from the toolchain folder", name)
	}
	return path, nil
}

func copyDirectory(source, destination string) error {
	entries, err := os.ReadDir(source)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(destination, 0o700); err != nil {
		return err
	}
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil {
			return err
		}
		sourcePath := filepath.Join(source, entry.Name())
		destinationPath := filepath.Join(destination, entry.Name())
		if info.IsDir() {
			if err := copyDirectory(sourcePath, destinationPath); err != nil {
				return err
			}
			continue
		}
		if !info.Mode().IsRegular() {
			continue
		}
		if err := copyFile(sourcePath, destinationPath); err != nil {
			return err
		}
	}
	return nil
}

func copyFile(source, destination string) error {
	info, err := os.Stat(source)
	if err != nil {
		return err
	}
	if !info.Mode().IsRegular() {
		return fmt.Errorf("%s is not a file", source)
	}
	contents, err := os.ReadFile(source)
	if err != nil {
		return err
	}
	return os.WriteFile(destination, contents, info.Mode().Perm())
}

func isDirectory(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func isRegularFile(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.Mode().IsRegular()
}
