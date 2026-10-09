package contentstore

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	gb "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (Store) ReadBroadcastPolicy(c context.Context, q tx.Queryer, rev string) (gb.ContentPolicy, error) {
	out := gb.ContentPolicy{Revision: rev}
	if q == nil {
		return out, gb.ErrContent
	}
	var manifest, raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, rev).Scan(&manifest); e != nil {
		return out, e
	}
	m, e := registry.DecodeManifestStrict([]byte(manifest))
	if e != nil || m.RevisionID != rev {
		return out, gb.ErrContent
	}
	good, e := manifestHasCapability([]byte(manifest), rev, "GUILD_BROADCAST_I7A8A")
	if e != nil || !good {
		return out, gb.ErrContent
	}
	if e = q.QueryRow(c, `SELECT payload::text FROM content_guild_broadcast_policies WHERE revision_id=$1`, rev).Scan(&raw); e != nil {
		return out, e
	}
	var normalized any
	if e = json.Unmarshal([]byte(raw), &normalized); e != nil {
		return out, e
	}
	data, e := json.Marshal(normalized)
	if e != nil {
		return out, e
	}
	h := sha256.Sum256(append(data, 10))
	if hex.EncodeToString(h[:]) != m.ArtifactSHA256s["guild_broadcast_policy.json"] {
		return out, gb.ErrContent
	}
	var p builtin.GuildBroadcastPolicy
	dec := json.NewDecoder(bytes.NewReader([]byte(raw)))
	dec.DisallowUnknownFields()
	if e = dec.Decode(&p); e != nil {
		return out, e
	}
	if e = p.Validate(); e != nil {
		return out, e
	}
	out.GuildCoreRevision = p.GuildCoreRevision
	out.PolicyID = p.PolicyID
	out.StoragePolicyID = p.StoragePolicyID
	out.TextSourceSHA256 = p.TextSourceSHA256
	out.MemberCap = p.MemberCap
	return out, out.Validate()
}

func (Store) HasGuildBroadcastCapabilityTx(c context.Context, q tx.Queryer, rev string) (bool, error) {
	if q == nil {
		return false, gb.ErrContent
	}
	var raw string
	if e := q.QueryRow(c, contentqueries.ReadContentRevisionManifest, rev).Scan(&raw); e != nil {
		return false, e
	}
	return manifestHasCapability([]byte(raw), rev, "GUILD_BROADCAST_I7A8A")
}
