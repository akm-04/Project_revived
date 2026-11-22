package operatoragent

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

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

// Credentials is the single root operator's password file.
type Credentials struct {
	Root string
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
	if password == "" {
		return Refuse(CodeBodyInvalid, "password is required")
	}
	if credentials.Exists() {
		return Refuse(CodeAlreadySetUp, "the agent is already set up")
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
