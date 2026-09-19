package mail

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
)

type Namespace uint8

const (
	Normal Namespace = iota + 1
	Region
)

func (n Namespace) String() string {
	if n == Normal {
		return "NORMAL"
	}
	if n == Region {
		return "REGION"
	}
	return "INVALID"
}
func (n Namespace) Valid() bool { return n == Normal || n == Region }

// WireIsRegion deliberately returns a boolean. Lua numeric 0 is truthy and is
// therefore forbidden for the stock normal-mail namespace.
func (n Namespace) WireIsRegion() (bool, error) {
	if !n.Valid() {
		return false, errors.New("invalid mail namespace")
	}
	return n == Region, nil
}

type Address struct {
	Namespace Namespace
	WireID    int64
}

func (a Address) Validate() error {
	if !a.Namespace.Valid() || a.WireID <= 0 {
		return errors.New("invalid mail address")
	}
	return nil
}
func (a Address) String() string { return a.Namespace.String() + ":" + strconv.FormatInt(a.WireID, 10) }

type PlatformEligibility uint8

const (
	AnyPlatform PlatformEligibility = iota + 1
	AndroidOnly
	IOSOnly
)

func (p PlatformEligibility) String() string {
	switch p {
	case AnyPlatform:
		return "ANY"
	case AndroidOnly:
		return "ANDROID"
	case IOSOnly:
		return "IOS"
	}
	return "INVALID"
}

type Attachment struct {
	Ordinal int
	Line    grant.Line
}

func (a Attachment) Validate() error {
	if a.Ordinal < 0 {
		return errors.New("negative attachment ordinal")
	}
	return a.Line.Validate()
}

type Record struct {
	MailUUID                   ids.UUID
	Recipient                  identity.PlayerID
	Address                    Address
	SourceKind, SourceKey      string
	Category                   int64
	Title, Sender, Body        string
	CreatedAt                  time.Time
	ExpiresAt                  *time.Time
	ReadAt                     *time.Time
	Shown                      bool
	ClaimedAt                  *time.Time
	Platform                   PlatformEligibility
	CompatibilityPolicyVersion string
	StateVersion               int64
	Attachments                []Attachment
}

func (r Record) Validate() error {
	if r.MailUUID.IsZero() || !r.Recipient.Valid() {
		return errors.New("mail identity required")
	}
	if err := r.Address.Validate(); err != nil {
		return err
	}
	if strings.TrimSpace(r.SourceKind) == "" || strings.TrimSpace(r.SourceKey) == "" || r.CreatedAt.IsZero() || strings.TrimSpace(r.CompatibilityPolicyVersion) == "" || r.StateVersion <= 0 {
		return errors.New("invalid mail record")
	}
	if r.Platform < AnyPlatform || r.Platform > IOSOnly {
		return errors.New("invalid platform eligibility")
	}
	if r.ExpiresAt != nil && !r.ExpiresAt.After(r.CreatedAt) {
		return errors.New("mail expiry must follow creation")
	}
	seen := map[int]struct{}{}
	for _, a := range r.Attachments {
		if err := a.Validate(); err != nil {
			return err
		}
		if _, ok := seen[a.Ordinal]; ok {
			return errors.New("duplicate attachment ordinal")
		}
		seen[a.Ordinal] = struct{}{}
	}
	return nil
}
func (r Record) Claimable(now time.Time) bool {
	if r.ClaimedAt != nil || len(r.Attachments) == 0 {
		return false
	}
	return r.ExpiresAt == nil || now.Before(*r.ExpiresAt)
}
func (r Record) New() bool { return r.ReadAt == nil }

// WireProjection preserves only source-proven mailbox fields plus durable
// content. is_region is always bool, never numeric zero.
func (r Record) WireProjection() (map[string]any, error) {
	if err := r.Validate(); err != nil {
		return nil, err
	}
	isRegion, _ := r.Address.Namespace.WireIsRegion()
	row := map[string]any{"id": r.Address.WireID, "is_region": isRegion, "category": r.Category, "title": r.Title, "from": r.Sender, "content": r.Body, "created_time": r.CreatedAt.Unix(), "is_new": int64(0), "is_shown": int64(0)}
	if r.ReadAt == nil {
		row["is_new"] = int64(1)
	}
	if r.Shown {
		row["is_shown"] = int64(1)
	}
	if r.ExpiresAt != nil {
		row["expired_time"] = r.ExpiresAt.Unix()
	}
	if len(r.Attachments) > 0 {
		attach := make([]any, 0, len(r.Attachments))
		for _, a := range r.Attachments {
			entry := map[string]any{"num": a.Line.Amount}
			if a.Line.Kind == grant.StackItem || a.Line.Kind == grant.PartnerEntity {
				entry["item"] = a.Line.ItemID
			} else {
				entry["item"] = a.Line.ResourceKey
			}
			attach = append(attach, entry)
		}
		row["attach"] = attach
	}
	return row, nil
}

func CanonicalAddresses(in []Address) ([]Address, error) {
	seen := map[string]Address{}
	for _, a := range in {
		if err := a.Validate(); err != nil {
			return nil, err
		}
		seen[a.String()] = a
	}
	out := make([]Address, 0, len(seen))
	for _, a := range seen {
		out = append(out, a)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Namespace != out[j].Namespace {
			return out[i].Namespace < out[j].Namespace
		}
		return out[i].WireID < out[j].WireID
	})
	return out, nil
}
func BatchSemanticKey(playerID identity.PlayerID, in []Address) (string, error) {
	if !playerID.Valid() {
		return "", errors.New("player required")
	}
	ordered, err := CanonicalAddresses(in)
	if err != nil {
		return "", err
	}
	if len(ordered) == 0 {
		return "", errors.New("empty mail batch")
	}
	var b strings.Builder
	b.WriteString(strconv.FormatInt(int64(playerID), 10))
	for _, a := range ordered {
		b.WriteByte(0)
		b.WriteString(a.String())
	}
	h := sha256.Sum256([]byte(b.String()))
	return hex.EncodeToString(h[:]), nil
}

func parsePipeIDs(raw string, ns Namespace, max int) ([]Address, error) {
	if raw == "" {
		return nil, nil
	}
	if max <= 0 {
		return nil, errors.New("positive mail batch bound required")
	}
	parts := strings.Split(raw, "|")
	if len(parts) > max {
		return nil, errors.New("mail id set exceeds bound")
	}
	out := make([]Address, 0, len(parts))
	for _, p := range parts {
		if p == "" {
			return nil, errors.New("empty mail id")
		}
		id, err := strconv.ParseInt(p, 10, 64)
		if err != nil || id <= 0 {
			return nil, fmt.Errorf("invalid mail id %q", p)
		}
		out = append(out, Address{Namespace: ns, WireID: id})
	}
	return out, nil
}
func ParseMID370(normalIDs, regionIDs string, maxAddresses int) ([]Address, error) {
	n, err := parsePipeIDs(normalIDs, Normal, maxAddresses)
	if err != nil {
		return nil, err
	}
	r, err := parsePipeIDs(regionIDs, Region, maxAddresses)
	if err != nil {
		return nil, err
	}
	if len(n)+len(r) > maxAddresses {
		return nil, errors.New("mail batch exceeds bound")
	}
	return CanonicalAddresses(append(n, r...))
}
