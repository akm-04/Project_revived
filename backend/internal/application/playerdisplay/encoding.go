package playerdisplay

import (
	"bytes"
	"encoding/json"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"io"
)

// Strong identity wrappers have private UUID fields; durable evidence uses
// explicit identities instead of silently encoding those wrappers as {}.
type actorWire struct {
	Account, UID, Session, Context                     string
	Server                                             int32
	Player, Generation, SessionVersion, ContextVersion int64
}

func encodeActor(a identity.ActorContext) actorWire {
	return actorWire{a.AccountID.UUID().String(), string(a.AccountUID), a.SessionID.UUID().String(), a.ContextID.UUID().String(), int32(a.LogicalServerID), int64(a.PlayerID), a.ContextGeneration, a.SessionLivenessVersion, a.ContextLivenessVersion}
}
func (w actorWire) decode() (identity.ActorContext, error) {
	var a identity.ActorContext
	u, e := ids.ParseUUID(w.Account)
	if e != nil {
		return a, e
	}
	a.AccountID, e = identity.AccountIDFrom(u)
	if e != nil {
		return a, e
	}
	u, e = ids.ParseUUID(w.Session)
	if e != nil {
		return a, e
	}
	a.SessionID, e = identity.SessionIDFrom(u)
	if e != nil {
		return a, e
	}
	u, e = ids.ParseUUID(w.Context)
	if e != nil {
		return a, e
	}
	a.ContextID, e = identity.ContextIDFrom(u)
	if e != nil {
		return a, e
	}
	a.AccountUID = identity.AccountUID(w.UID)
	a.LogicalServerID = identity.LogicalServerID(w.Server)
	a.PlayerID = identity.PlayerID(w.Player)
	a.ContextGeneration = w.Generation
	a.SessionLivenessVersion = w.SessionVersion
	a.ContextLivenessVersion = w.ContextVersion
	if !a.AccountUID.Valid() || !a.PlayerID.Valid() || !a.LogicalServerID.Valid() || a.ContextGeneration < 1 || a.SessionLivenessVersion < 1 || a.ContextLivenessVersion < 1 {
		return a, ErrConflict
	}
	return a, nil
}
func strict(data []byte, out any) error {
	d := json.NewDecoder(bytes.NewReader(data))
	d.DisallowUnknownFields()
	if e := d.Decode(out); e != nil {
		return e
	}
	var extra any
	if d.Decode(&extra) != io.EOF {
		return ErrConflict
	}
	return nil
}

type resultAlias Result

func (r Result) MarshalJSON() ([]byte, error) {
	return json.Marshal(struct {
		*resultAlias
		Identity actorWire `json:"actor_identity"`
	}{(*resultAlias)(&r), encodeActor(r.Actor)})
}
func (r *Result) UnmarshalJSON(data []byte) error {
	wire := struct {
		*resultAlias
		Identity actorWire `json:"actor_identity"`
	}{resultAlias: (*resultAlias)(r)}
	if e := strict(data, &wire); e != nil {
		return e
	}
	a, e := wire.Identity.decode()
	r.Actor = a
	return e
}

type admissionAlias Admission

func (j Admission) MarshalJSON() ([]byte, error) {
	return json.Marshal(struct {
		*admissionAlias
		Identity actorWire `json:"actor_identity"`
	}{(*admissionAlias)(&j), encodeActor(j.Actor)})
}
func (j *Admission) UnmarshalJSON(data []byte) error {
	wire := struct {
		*admissionAlias
		Identity actorWire `json:"actor_identity"`
	}{admissionAlias: (*admissionAlias)(j)}
	if e := strict(data, &wire); e != nil {
		return e
	}
	a, e := wire.Identity.decode()
	j.Actor = a
	return e
}
