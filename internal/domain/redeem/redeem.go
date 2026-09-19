package redeem

import (
	"crypto/hmac"
	"crypto/sha256"
	"errors"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

const StockFunctionLevel int64 = 10

type Normalization uint8

const (
	ExactCode Normalization = iota + 1
	TrimASCIIWhitespace
	TrimAndUpperASCII
)

func Normalize(raw string, p Normalization) (string, error) {
	if len(raw) == 0 || len(raw) > 256 {
		return "", errors.New("invalid redeem code length")
	}
	v := raw
	switch p {
	case ExactCode:
	case TrimASCIIWhitespace:
		v = strings.Trim(v, " \t\r\n")
	case TrimAndUpperASCII:
		v = strings.ToUpper(strings.Trim(v, " \t\r\n"))
	default:
		return "", errors.New("unknown normalization policy")
	}
	if v == "" {
		return "", errors.New("empty normalized redeem code")
	}
	return v, nil
}

// LookupDigest prevents raw submitted codes from becoming durable lookup/log keys.
func LookupDigest(secret []byte, normalized string) ([32]byte, error) {
	var out [32]byte
	if len(secret) < 16 || normalized == "" {
		return out, errors.New("redeem digest configuration incomplete")
	}
	h := hmac.New(sha256.New, secret)
	_, _ = h.Write([]byte("gxb-v2/redeem-code\x00"))
	_, _ = h.Write([]byte(normalized))
	copy(out[:], h.Sum(nil))
	return out, nil
}

type SubjectType string

const (
	PlayerSubject         SubjectType = "PLAYER"
	AccountSubject        SubjectType = "ACCOUNT"
	PlayerOnLogicalServer SubjectType = "PLAYER_ON_LOGICAL_SERVER"
	GlobalSingleUse       SubjectType = "GLOBAL_SINGLE_USE"
)

type CampaignStatus string

const (
	Draft    CampaignStatus = "DRAFT"
	Active   CampaignStatus = "ACTIVE"
	Disabled CampaignStatus = "DISABLED"
	Expired  CampaignStatus = "EXPIRED"
)

type AudiencePolicy struct {
	MinLevel       *int64
	MaxLevel       *int64
	LogicalServers map[identity.LogicalServerID]struct{}
}
type Campaign struct {
	Status        CampaignStatus
	Subject       SubjectType
	StartsAt      *time.Time
	EndsAt        *time.Time
	Audience      AudiencePolicy
	PolicyVersion string
}
type Actor struct {
	PlayerID        identity.PlayerID
	AccountID       identity.AccountID
	LogicalServerID identity.LogicalServerID
	Level           int64
}

func Eligible(c Campaign, a Actor, now time.Time) error {
	if c.Status != Active {
		return errors.New("redeem campaign not active")
	}
	if !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || a.Level < StockFunctionLevel {
		return errors.New("redeem function not eligible")
	}
	if now.IsZero() {
		return errors.New("authoritative time required")
	}
	if c.PolicyVersion == "" {
		return errors.New("redeem policy version required")
	}
	if c.StartsAt != nil && now.Before(*c.StartsAt) {
		return errors.New("redeem campaign not started")
	}
	if c.EndsAt != nil && !now.Before(*c.EndsAt) {
		return errors.New("redeem campaign ended")
	}
	if c.Audience.MinLevel != nil && a.Level < *c.Audience.MinLevel {
		return errors.New("redeem level below campaign minimum")
	}
	if c.Audience.MaxLevel != nil && a.Level > *c.Audience.MaxLevel {
		return errors.New("redeem level above campaign maximum")
	}
	if len(c.Audience.LogicalServers) > 0 {
		if _, ok := c.Audience.LogicalServers[a.LogicalServerID]; !ok {
			return errors.New("redeem logical server not eligible")
		}
	}
	return nil
}
