package realtime

import (
	"errors"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

func TestSourceDirectRolesAreSourceBoundAndDescriptorsAreS2C(t *testing.T) {
	cases := []struct {
		mid   uint16
		roles []Role
	}{
		{mids.MIDChatFromPlayer, []Role{World}},
		{mids.MIDChatFromFriend, []Role{World}},
		{mids.MIDChatMessage, []Role{World, Guild, Service}},
		{mids.MIDForceReload, []Role{World}},
		{mids.MIDGuildBroadcast, []Role{Guild}},
	}
	for _, tc := range cases {
		got, ok := SourceDirectRoles(tc.mid)
		if !ok || !reflect.DeepEqual(got, tc.roles) {
			t.Fatalf("mid=%d roles=%v ok=%v", tc.mid, got, ok)
		}
		d, ok := mids.Lookup(tc.mid)
		if !ok || d.Transport != mids.TCP || d.Direction != mids.S2C || d.Encoding != mids.AMF3 {
			t.Fatalf("mid=%d descriptor=%+v ok=%v", tc.mid, d, ok)
		}
	}
	if _, ok := SourceDirectRoles(mids.MIDWorldNotice); ok {
		t.Fatal("generic notice inherited a direct-event role policy")
	}
}

func TestEventRegistryDirectSchemasFailClosed(t *testing.T) {
	empty, err := NewEventRegistry(nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	obj := &amf3.Object{}
	if err := empty.ValidateDirect(mids.MIDChatFromPlayer, World, obj); !errors.Is(err, ErrUnknownS2CSchema) {
		t.Fatalf("unregistered direct err=%v", err)
	}
	reg, err := NewEventRegistry([]DirectRegistration{{MID: mids.MIDChatFromPlayer, Roles: []Role{World}, Validate: RequireAMF3Object}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := reg.ValidateDirect(mids.MIDChatFromPlayer, World, obj); err != nil {
		t.Fatal(err)
	}
	if err := reg.ValidateDirect(mids.MIDChatFromPlayer, Guild, obj); !errors.Is(err, ErrWrongS2CRole) {
		t.Fatalf("wrong role err=%v", err)
	}
	if err := reg.ValidateDirect(mids.MIDChatFromPlayer, World, map[string]any{}); !errors.Is(err, ErrInvalidS2CPayload) {
		t.Fatalf("invalid payload err=%v", err)
	}
	if _, err := NewEventRegistry([]DirectRegistration{{MID: mids.MIDChatFromPlayer, Roles: []Role{Guild}, Validate: RequireAMF3Object}}, nil); !errors.Is(err, ErrInvalidS2CRegistration) {
		t.Fatalf("source-contradicting role registration err=%v", err)
	}
	if _, err := NewEventRegistry([]DirectRegistration{
		{MID: mids.MIDChatFromPlayer, Roles: []Role{World}, Validate: RequireAMF3Object},
		{MID: mids.MIDChatFromPlayer, Roles: []Role{World}, Validate: RequireAMF3Object},
	}, nil); !errors.Is(err, ErrDuplicateS2CSchema) {
		t.Fatalf("duplicate direct err=%v", err)
	}
}

func TestEventRegistryNoticeSchemasUseParentNamespaceAndType(t *testing.T) {
	payload := &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: 7.0}}}
	empty, _ := NewEventRegistry(nil, nil)
	if err := empty.ValidateNotice(mids.MIDPlayerNotice, NoticeNamespaceGeneric, World, payload); !errors.Is(err, ErrUnknownS2CSchema) {
		t.Fatalf("zero registrations err=%v", err)
	}
	reg, err := NewEventRegistry(nil, []NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: NoticeNamespaceGeneric, NoticeType: 7, Roles: []Role{World}, Validate: RequireAMF3Object},
		{ParentMID: mids.MIDPlayerNotice, Namespace: NoticeNamespaceFriend, NoticeType: 7, Roles: []Role{Guild}, Validate: RequireAMF3Object},
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := reg.ValidateNotice(mids.MIDPlayerNotice, NoticeNamespaceGeneric, World, payload); err != nil {
		t.Fatal(err)
	}
	if err := reg.ValidateNotice(mids.MIDPlayerNotice, NoticeNamespaceFriend, World, payload); !errors.Is(err, ErrWrongS2CRole) {
		t.Fatalf("namespace separation/wrong role err=%v", err)
	}
	if err := reg.ValidateNotice(mids.MIDWorldNotice, NoticeNamespaceGeneric, World, payload); !errors.Is(err, ErrUnknownS2CSchema) {
		t.Fatalf("parent separation err=%v", err)
	}
	if err := reg.ValidateNotice(mids.MIDPlayerNotice, NoticeNamespaceGeneric, World, &amf3.Object{}); !errors.Is(err, ErrInvalidS2CPayload) {
		t.Fatalf("missing notice_type err=%v", err)
	}
	fractional := &amf3.Object{Properties: []amf3.Property{{Name: "notice_type", Value: 7.5}}}
	if err := reg.ValidateNotice(mids.MIDPlayerNotice, NoticeNamespaceGeneric, World, fractional); !errors.Is(err, ErrInvalidS2CPayload) {
		t.Fatalf("fractional notice_type err=%v", err)
	}
	if _, err := NewEventRegistry(nil, []NoticeRegistration{
		{ParentMID: mids.MIDPlayerNotice, Namespace: NoticeNamespaceGeneric, NoticeType: 7, Roles: []Role{World}, Validate: RequireAMF3Object},
		{ParentMID: mids.MIDPlayerNotice, Namespace: NoticeNamespaceGeneric, NoticeType: 7, Roles: []Role{World}, Validate: RequireAMF3Object},
	}); !errors.Is(err, ErrDuplicateS2CSchema) {
		t.Fatalf("duplicate notice err=%v", err)
	}
}
