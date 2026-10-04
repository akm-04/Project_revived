package realtime

import (
	"errors"
	"fmt"
	"math"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

var (
	ErrInvalidS2CRegistration = errors.New("invalid realtime S2C registration")
	ErrDuplicateS2CSchema     = errors.New("duplicate realtime S2C schema")
	ErrUnknownS2CSchema       = errors.New("unknown realtime S2C schema")
	ErrWrongS2CRole           = errors.New("realtime S2C role not allowed")
	ErrInvalidS2CPayload      = errors.New("invalid realtime S2C payload")
)

type PayloadValidator func(any) error

type DirectRegistration struct {
	MID      uint16
	Roles    []Role
	Validate PayloadValidator
}

type NoticeNamespace string

const (
	NoticeNamespaceGeneric NoticeNamespace = "NOTICE_TYPE"
	NoticeNamespaceFriend  NoticeNamespace = "FRIEND_NOTICE_TYPE"
)

func (n NoticeNamespace) Valid() bool {
	return n == NoticeNamespaceGeneric || n == NoticeNamespaceFriend
}

type NoticeRegistration struct {
	ParentMID  uint16
	Namespace  NoticeNamespace
	NoticeType int64
	Roles      []Role
	Validate   PayloadValidator
}

type directSchema struct {
	roles    map[Role]struct{}
	validate PayloadValidator
}

type noticeKey struct {
	parent    uint16
	namespace NoticeNamespace
	typeID    int64
}

type noticeSchema struct {
	roles    map[Role]struct{}
	validate PayloadValidator
}

// EventRegistry is immutable after construction. Descriptor presence does not
// activate a producer: publication requires an explicit exact schema entry.
type EventRegistry struct {
	direct  map[uint16]directSchema
	notices map[noticeKey]noticeSchema
}

func NewEventRegistry(direct []DirectRegistration, notices []NoticeRegistration) (EventRegistry, error) {
	out := EventRegistry{direct: make(map[uint16]directSchema, len(direct)), notices: make(map[noticeKey]noticeSchema, len(notices))}
	for _, reg := range direct {
		allowed, ok := SourceDirectRoles(reg.MID)
		if !ok || reg.Validate == nil {
			return EventRegistry{}, ErrInvalidS2CRegistration
		}
		roles, err := validateRoleSubset(reg.Roles, allowed)
		if err != nil {
			return EventRegistry{}, err
		}
		if _, exists := out.direct[reg.MID]; exists {
			return EventRegistry{}, fmt.Errorf("%w: MID %d", ErrDuplicateS2CSchema, reg.MID)
		}
		out.direct[reg.MID] = directSchema{roles: roles, validate: reg.Validate}
	}
	for _, reg := range notices {
		if !noticeParent(reg.ParentMID) || !reg.Namespace.Valid() || reg.Validate == nil {
			return EventRegistry{}, ErrInvalidS2CRegistration
		}
		roles, err := validateRoles(reg.Roles)
		if err != nil {
			return EventRegistry{}, err
		}
		key := noticeKey{parent: reg.ParentMID, namespace: reg.Namespace, typeID: reg.NoticeType}
		if _, exists := out.notices[key]; exists {
			return EventRegistry{}, fmt.Errorf("%w: parent=%d namespace=%s notice_type=%d", ErrDuplicateS2CSchema, reg.ParentMID, reg.Namespace, reg.NoticeType)
		}
		out.notices[key] = noticeSchema{roles: roles, validate: reg.Validate}
	}
	return out, nil
}

// SourceDirectRoles returns the stock-source physical role policy for direct
// server pushes selected by the I7A-2 contract. It is descriptor evidence, not
// producer activation.
func SourceDirectRoles(mid uint16) ([]Role, bool) {
	var roles []Role
	switch mid {
	case mids.MIDChatFromPlayer, mids.MIDChatFromFriend, mids.MIDForceReload:
		roles = []Role{World}
	case mids.MIDChatMessage:
		roles = []Role{World, Guild, Service}
	case mids.MIDGuildBroadcast:
		roles = []Role{Guild}
	default:
		return nil, false
	}
	d, ok := mids.Lookup(mid)
	if !ok || d.Transport != mids.TCP || d.Direction != mids.S2C || d.Encoding != mids.AMF3 {
		return nil, false
	}
	return append([]Role(nil), roles...), true
}

func (r EventRegistry) ValidateDirect(mid uint16, role Role, payload any) error {
	if !role.Valid() {
		return ErrWrongS2CRole
	}
	schema, ok := r.direct[mid]
	if !ok {
		return fmt.Errorf("%w: MID %d", ErrUnknownS2CSchema, mid)
	}
	if _, ok := schema.roles[role]; !ok {
		return fmt.Errorf("%w: MID %d role=%s", ErrWrongS2CRole, mid, role)
	}
	if err := schema.validate(payload); err != nil {
		return fmt.Errorf("%w: MID %d: %v", ErrInvalidS2CPayload, mid, err)
	}
	return nil
}

func (r EventRegistry) ValidateNotice(parent uint16, namespace NoticeNamespace, role Role, payload any) error {
	if !role.Valid() || !namespace.Valid() || !noticeParent(parent) {
		return ErrInvalidS2CPayload
	}
	typeID, err := noticeType(payload)
	if err != nil {
		return err
	}
	key := noticeKey{parent: parent, namespace: namespace, typeID: typeID}
	schema, ok := r.notices[key]
	if !ok {
		return fmt.Errorf("%w: parent=%d namespace=%s notice_type=%d", ErrUnknownS2CSchema, parent, namespace, typeID)
	}
	if _, ok := schema.roles[role]; !ok {
		return fmt.Errorf("%w: parent=%d role=%s", ErrWrongS2CRole, parent, role)
	}
	if err := schema.validate(payload); err != nil {
		return fmt.Errorf("%w: parent=%d notice_type=%d: %v", ErrInvalidS2CPayload, parent, typeID, err)
	}
	return nil
}

func RequireAMF3Object(v any) error {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return errors.New("AMF3 object required")
	}
	_, err := o.StrictMap()
	return err
}

func noticeType(v any) (int64, error) {
	o, ok := v.(*amf3.Object)
	if !ok || o == nil {
		return 0, fmt.Errorf("%w: notice payload must be AMF3 object", ErrInvalidS2CPayload)
	}
	m, err := o.StrictMap()
	if err != nil {
		return 0, fmt.Errorf("%w: %v", ErrInvalidS2CPayload, err)
	}
	raw, ok := m["notice_type"]
	if !ok {
		return 0, fmt.Errorf("%w: notice_type missing", ErrInvalidS2CPayload)
	}
	switch x := raw.(type) {
	case int:
		return int64(x), nil
	case int32:
		return int64(x), nil
	case int64:
		return x, nil
	case uint:
		if uint64(x) > math.MaxInt64 {
			return 0, fmt.Errorf("%w: notice_type overflow", ErrInvalidS2CPayload)
		}
		return int64(x), nil
	case uint32:
		return int64(x), nil
	case uint64:
		if x > math.MaxInt64 {
			return 0, fmt.Errorf("%w: notice_type overflow", ErrInvalidS2CPayload)
		}
		return int64(x), nil
	case float64:
		if math.IsNaN(x) || math.IsInf(x, 0) || x != math.Trunc(x) || x < math.MinInt64 || x > math.MaxInt64 {
			return 0, fmt.Errorf("%w: notice_type must be integral", ErrInvalidS2CPayload)
		}
		return int64(x), nil
	default:
		return 0, fmt.Errorf("%w: notice_type type %T", ErrInvalidS2CPayload, raw)
	}
}

func noticeParent(mid uint16) bool {
	if mid != mids.MIDWorldNotice && mid != mids.MIDPlayerNotice {
		return false
	}
	d, ok := mids.Lookup(mid)
	return ok && d.Transport == mids.TCP && d.Direction == mids.S2C && d.Encoding == mids.AMF3
}

func validateRoleSubset(in, allowed []Role) (map[Role]struct{}, error) {
	roles, err := validateRoles(in)
	if err != nil {
		return nil, err
	}
	allow := make(map[Role]struct{}, len(allowed))
	for _, r := range allowed {
		allow[r] = struct{}{}
	}
	for r := range roles {
		if _, ok := allow[r]; !ok {
			return nil, fmt.Errorf("%w: role %s contradicts source policy", ErrInvalidS2CRegistration, r)
		}
	}
	return roles, nil
}

func validateRoles(in []Role) (map[Role]struct{}, error) {
	if len(in) == 0 {
		return nil, ErrInvalidS2CRegistration
	}
	roles := make(map[Role]struct{}, len(in))
	for _, r := range in {
		if !r.Valid() {
			return nil, ErrInvalidS2CRegistration
		}
		if _, exists := roles[r]; exists {
			return nil, ErrInvalidS2CRegistration
		}
		roles[r] = struct{}{}
	}
	return roles, nil
}
