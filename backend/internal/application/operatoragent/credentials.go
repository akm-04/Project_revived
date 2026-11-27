package operatoragent

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/argon2"
)

// Argon2id parameters (I11A_1_PLAN "Agent decisions"): tune them here, never in
// a call site.
const (
	argonTime    uint32 = 3
	argonMemory  uint32 = 64 * 1024
	argonThreads uint8  = 4
	argonSalt    uint32 = 16
	argonKey     uint32 = 32
)

// MinimumPasswordLength is the setup minimum (design A.1): setup and password
// change both refuse a shorter password.
const MinimumPasswordLength = 8

// Credentials is the single root operator's password file.
type Credentials struct {
	Root string

	mutex            sync.Mutex
	cachedGeneration string
	cachedSize       int64
	cachedModTime    time.Time
}

// NewCredentials names the root folder; nothing is created until Setup.
func NewCredentials(root string) *Credentials { return &Credentials{Root: root} }

func (credentials *Credentials) passwordPath() string {
	return filepath.Join(credentials.Root, PasswordFileName)
}

// Exists reports whether the root password was set.
func (credentials *Credentials) Exists() bool {
	info, err := os.Stat(credentials.passwordPath())
	return err == nil && info.Mode().IsRegular()
}

// Setup writes the password hash once. A second setup is a refusal, not an
// overwrite.
func (credentials *Credentials) Setup(password string) error {
	if credentials.Exists() {
		return Refuse(CodeAlreadySetUp, "the agent is already set up")
	}
	if err := validateNewPassword(password); err != nil {
		return err
	}
	encoded, err := hashPassword(password)
	if err != nil {
		return err
	}
	file, err := os.OpenFile(credentials.passwordPath(), os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if err != nil {
		if errors.Is(err, os.ErrExist) {
			return Refuse(CodeAlreadySetUp, "the agent is already set up")
		}
		return err
	}
	if _, err := file.WriteString(encoded + "\n"); err != nil {
		_ = file.Close()
		return err
	}
	return file.Close()
}

// ChangePassword verifies the current password with the same check the login
// uses, then replaces the hash atomically. The new generation ends every live
// session on its next request (design A.1).
func (credentials *Credentials) ChangePassword(current, replacement string) error {
	if err := credentials.Verify(current); err != nil {
		return err
	}
	if err := validateNewPassword(replacement); err != nil {
		return err
	}
	if replacement == current {
		return Refuse(CodePasswordSame, "the new password must differ from the current one")
	}
	return credentials.writePassword(replacement)
}

// ResetPassword writes a new hash without a current password: the local file is
// the authority, so a forgotten password is reset from the machine (design A.2).
func (credentials *Credentials) ResetPassword(replacement string) error {
	if !credentials.Exists() {
		return Refuse(CodeSetupRequired, "the agent has no root password yet")
	}
	if err := validateNewPassword(replacement); err != nil {
		return err
	}
	return credentials.writePassword(replacement)
}

func validateNewPassword(password string) error {
	if password == "" {
		return Refuse(CodeBodyInvalid, "password is required")
	}
	if len(password) < MinimumPasswordLength {
		return Refuse(CodePasswordTooShort, fmt.Sprintf("the password must be at least %d characters", MinimumPasswordLength))
	}
	return nil
}

func (credentials *Credentials) writePassword(password string) error {
	encoded, err := hashPassword(password)
	if err != nil {
		return err
	}
	return writePasswordAtomically(credentials.passwordPath(), []byte(encoded+"\n"))
}

// writePasswordAtomically replaces the password file with temp + fsync + rename,
// so a reader never sees a truncated hash and a crash keeps the old password.
func writePasswordAtomically(path string, contents []byte) error {
	directory := filepath.Dir(path)
	temporary, err := os.CreateTemp(directory, ".root.passwd-*")
	if err != nil {
		return err
	}
	temporaryName := temporary.Name()
	cleanup := func() {
		_ = temporary.Close()
		_ = os.Remove(temporaryName)
	}
	if _, err := temporary.Write(contents); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Sync(); err != nil {
		cleanup()
		return err
	}
	if err := temporary.Close(); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if err := os.Rename(temporaryName, path); err != nil {
		_ = os.Remove(temporaryName)
		return err
	}
	if handle, err := os.Open(directory); err == nil {
		_ = handle.Sync()
		_ = handle.Close()
	}
	return nil
}

// Generation hashes the stored password line. A session records the generation
// it logged in with, so a password change or an offline reset refuses every
// older token on its next request. The file is re-read when its size or mtime
// changes.
func (credentials *Credentials) Generation() (string, error) {
	path := credentials.passwordPath()
	info, err := os.Stat(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", Refuse(CodeSetupRequired, "the agent has no root password yet")
		}
		return "", err
	}
	credentials.mutex.Lock()
	defer credentials.mutex.Unlock()
	if credentials.cachedGeneration != "" && credentials.cachedSize == info.Size() && credentials.cachedModTime.Equal(info.ModTime()) {
		return credentials.cachedGeneration, nil
	}
	contents, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	digest := sha256.Sum256([]byte(strings.TrimSpace(string(contents))))
	credentials.cachedGeneration = hex.EncodeToString(digest[:])
	credentials.cachedSize = info.Size()
	credentials.cachedModTime = info.ModTime()
	return credentials.cachedGeneration, nil
}

// Verify checks the password in constant time. A missing file is
// AGENT_SETUP_REQUIRED; a wrong password is AGENT_LOGIN_REFUSED.
func (credentials *Credentials) Verify(password string) error {
	encoded, err := os.ReadFile(credentials.passwordPath())
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return Refuse(CodeSetupRequired, "the agent has no root password yet")
		}
		return err
	}
	if !verifyPassword(strings.TrimSpace(string(encoded)), password) {
		return Refuse(CodeLoginRefused, "wrong password")
	}
	return nil
}

// VerifyAndGeneration checks password against one snapshot of the stored
// record and returns the generation of those same bytes. A password change or
// an offline reset between the check and session minting therefore cannot lend
// its new generation to an older credential proof.
func (credentials *Credentials) VerifyAndGeneration(password string) (string, error) {
	contents, err := os.ReadFile(credentials.passwordPath())
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", Refuse(CodeSetupRequired, "the agent has no root password yet")
		}
		return "", err
	}
	encoded := strings.TrimSpace(string(contents))
	if !verifyPassword(encoded, password) {
		return "", Refuse(CodeLoginRefused, "wrong password")
	}
	digest := sha256.Sum256([]byte(encoded))
	return hex.EncodeToString(digest[:]), nil
}

func hashPassword(password string) (string, error) {
	salt := make([]byte, argonSalt)
	if _, err := rand.Read(salt); err != nil {
		return "", err
	}
	derived := argon2.IDKey([]byte(password), salt, argonTime, argonMemory, argonThreads, argonKey)
	return fmt.Sprintf("$argon2id$v=19$m=%d,t=%d,p=%d$%s$%s",
		argonMemory, argonTime, argonThreads,
		base64.RawStdEncoding.EncodeToString(salt),
		base64.RawStdEncoding.EncodeToString(derived)), nil
}

func verifyPassword(encoded, password string) bool {
	parts := strings.Split(encoded, "$")
	if len(parts) != 6 || parts[0] != "" || parts[1] != "argon2id" || parts[2] != "v=19" {
		return false
	}
	memory, timeCost, threads, err := parseArgonParameters(parts[3])
	if err != nil || memory == 0 || timeCost == 0 || threads == 0 {
		return false
	}
	salt, err := base64.RawStdEncoding.DecodeString(parts[4])
	if err != nil {
		return false
	}
	expected, err := base64.RawStdEncoding.DecodeString(parts[5])
	if err != nil || len(expected) == 0 {
		return false
	}
	derived := argon2.IDKey([]byte(password), salt, timeCost, memory, threads, uint32(len(expected)))
	return subtle.ConstantTimeCompare(derived, expected) == 1
}

func parseArgonParameters(text string) (memory, timeCost uint32, threads uint8, err error) {
	for parameter := range strings.SplitSeq(text, ",") {
		name, value, found := strings.Cut(parameter, "=")
		if !found {
			return 0, 0, 0, errors.New("malformed argon2 parameter")
		}
		parsed, parseErr := strconv.ParseUint(value, 10, 32)
		if parseErr != nil {
			return 0, 0, 0, parseErr
		}
		switch name {
		case "m":
			memory = uint32(parsed)
		case "t":
			timeCost = uint32(parsed)
		case "p":
			threads = uint8(parsed)
		default:
			return 0, 0, 0, errors.New("unknown argon2 parameter")
		}
	}
	return memory, timeCost, threads, nil
}
