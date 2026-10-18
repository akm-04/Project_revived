package publicprofile

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
	"time"
)

var ErrProfileProvider = errors.New("required public profile provider unavailable or incoherent")

// The production gate permits genuine empty slots but never fabricates a rich record.
type UnavailableShowcaseRecords struct{}

func (UnavailableShowcaseRecords) RecordTx(context.Context, characterasset.CoherentReadScope, identity.PlayerID, int64) (map[string]any, error) {
	return nil, ErrShowcaseUnavailable
}

type GuildReader interface {
	ReadPublicGuildTx(context.Context, tx.Scope, identity.PlayerID, identity.PlayerID, string, time.Time) (guildcore.PublicView, error)
}
type HistoryObservation struct {
	PlayerID        identity.PlayerID
	Subtype         int16
	ContentRevision string
	ObservedAt      time.Time
	SourceVersion   int64
	Fields          map[string]any
}
type HistoryReader interface {
	ReadPublicHistoryTx(context.Context, tx.Scope, identity.PlayerID, int16, string, time.Time) (HistoryObservation, error)
}
type ReadRequest struct {
	MID     uint16
	Target  identity.PlayerID
	Subtype int16
	Index   int
}
type ReadService struct {
	Runner     tx.Runner
	Fresh      tx.Queryer
	Time       gen.TimeAuthority
	Content    ShowcaseContentReader
	Basic      BasicReader
	Display    i5.TxEffectivePlayerDisplayReader
	Guilds     GuildReader
	Feedback   FeedbackReader
	Comments   CommentReader
	Media      MediaStore
	Metrics    MetricReader
	Slots      ShowcaseStore
	Characters ShowcaseCharacterReader
	Records    ShowcaseRecordBuilder
	History    HistoryReader
}

// Pin one instant/revision before entering one caller transaction. Providers
// neither discover current content/time nor start nested transactions.
func (s ReadService) Read(c context.Context, a identity.ActorContext, q ReadRequest, o operation.Context) (map[string]any, error) {
	if s.Runner.DB == nil || s.Fresh == nil || s.Content == nil || s.Time == nil {
		return nil, ErrProfileProvider
	}
	if q.MID == 1840 {
		q.Target = a.PlayerID
	} else if !q.Target.Valid() {
		return nil, ErrCommand
	}
	at, e := s.Time.Now(c)
	if e != nil {
		return nil, e
	}
	rev, e := s.Content.ActiveRevision(c, s.Fresh)
	if e != nil {
		return nil, e
	}
	// Preserve existing operation policies while pinning the selected metric
	// content before the caller transaction; a conflicting caller pin fails closed.
	if pin, ok := o.Policies.Get("content"); ok && pin != rev {
		return nil, ErrContent
	}
	if _, ok := o.Policies.Get("content"); !ok {
		refs := append(o.Policies.Refs(), policy.Ref{Name: "content", Version: rev})
		o.Policies, e = policy.NewSet(refs...)
		if e != nil {
			return nil, e
		}
	}
	o, e = bindRosterPolicy(o)
	if e != nil {
		return nil, e
	}
	var out map[string]any
	res, e := s.Runner.Run(c, o, i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var e error
		out, e = s.ReadTx(c, sc, a, q, rev, at)
		return e
	})
	if e != nil {
		return nil, e
	}
	if res.Outcome != tx.DefiniteCommit {
		return nil, ErrConflict
	}
	return out, nil
}
func (s ReadService) ReadTx(c context.Context, sc tx.Scope, a identity.ActorContext, q ReadRequest, rev string, at time.Time) (map[string]any, error) {
	if q.MID == 1840 {
		if q.Target != a.PlayerID || s.Metrics == nil {
			return nil, ErrCommand
		}
		if _, e := s.Basic.ReadBasicTx(c, sc, a, a.PlayerID, rev, at); e != nil {
			return nil, e
		}
		values, e := s.metrics(c, sc, a.PlayerID, []int64{1011}, rev, at)
		if e != nil {
			return nil, e
		}
		return map[string]any{"all_show_types": values}, nil
	}
	if q.MID == 1838 {
		selected, e := (ShowcaseReader{Basic: s.Basic, Slots: s.Slots, Content: s.Content, Characters: s.Characters}).ReadSelectedTx(c, sc, a, q.Target, q.Index, rev, at)
		if e != nil {
			return nil, e
		}
		if s.Records == nil {
			return nil, ErrShowcaseUnavailable
		}
		scope, e := characterasset.NewCoherentReadScope(sc, rev, at)
		if e != nil {
			return nil, e
		}
		id := selected.Snapshot.Selection[q.Index-1]
		v, e := s.Records.RecordTx(c, scope, q.Target, id)
		if e != nil {
			return nil, e
		}
		if e = validateWireRecord(id, v); e != nil {
			return nil, e
		}
		return cloneRecord(v)
	}
	if q.MID != 1829 {
		return nil, ErrCommand
	}
	sub := q.Subtype
	if sub == 0 {
		sub = 1
	}
	if sub < 1 || sub > 6 || sub == 5 {
		return nil, ErrCommand
	}
	basic, e := s.Basic.ReadBasicTx(c, sc, a, q.Target, rev, at)
	if e != nil {
		return nil, e
	}
	if sub != 1 && !basic.Eligible[sub] {
		return nil, ErrShowcasePrivate
	}
	if sub == 2 || sub == 3 {
		if s.History == nil {
			return nil, ErrProfileProvider
		}
		v, e := s.History.ReadPublicHistoryTx(c, sc, q.Target, sub, rev, at)
		if e != nil {
			return nil, e
		}
		if v.PlayerID != q.Target || v.Subtype != sub || v.ContentRevision != rev || !v.ObservedAt.Equal(at) || v.SourceVersion <= 0 {
			return nil, ErrProfileProvider
		}
		keys := []string{"arena_performance", "region_arena_performance", "super_arena_performance"}
		if sub == 3 {
			keys = []string{"arena_records", "region_arena_records", "super_arena_records"}
		}
		for _, k := range keys {
			if v.Fields[k] == nil {
				return nil, ErrProfileProvider
			}
		}
		return cloneRecord(v.Fields)
	}
	if sub == 4 {
		if s.Comments == nil {
			return nil, ErrProfileProvider
		}
		v, e := s.Comments.ObserveCommentsTx(c, sc, q.Target, a.PlayerID, rev, at, 0, 20, true)
		if e != nil {
			return nil, e
		}
		if v.Target != q.Target || v.Actor != a.PlayerID || v.Revision != rev || !v.ObservedAt.Equal(at) || v.Count < 0 || v.RootVersion < 0 {
			return nil, ErrProfileProvider
		}
		out := v.Wire()
		if e = s.media(c, sc, q.Target, rev, at, out); e != nil {
			return nil, e
		}
		return out, nil
	}
	if s.Display == nil {
		return nil, ErrProfileProvider
	}
	display, e := s.Display.ReadEffectivePlayerDisplayTx(c, sc.Tx, q.Target, rev, at)
	if e != nil {
		return nil, e
	}
	if display.ContentRevision != rev || !display.ObservedAt.Equal(at) || display.ProfileVersion != basic.PlayerProfileVersion || display.ProgressionVersion != basic.ProgressionVersion || display.AvatarID <= 0 || display.AvatarFrameID < 0 {
		return nil, ErrProfileProvider
	}
	id := basic.Identity
	info := map[string]any{"player_id": int64(id.PlayerID), "region": int32(id.Server), "player_name": id.Name, "avatar_id": display.AvatarID, "avatar_frame_id": display.AvatarFrameID, "player_type": id.PlayerType, "lev": id.Level, "exp": id.Exp}
	out := map[string]any{"player_info": info, "is_in_blacklist": basic.ActorBlocked}
	if sub == 1 && !basic.Eligible[1] {
		return out, nil
	}
	snapshot, e := s.Basic.Roots.ReadSnapshotTx(c, sc, q.Target, rev, at)
	if e != nil {
		return nil, e
	}
	prefs := snapshot.Root.Preferences
	out["intro"] = basic.Intro
	out["share_switch"] = prefs.ShareSwitch
	out["is_first_time"] = prefs.IsFirstTime
	out["hide_types"] = prefs.HideSubtypes
	// SYSTEM also refreshes the source basic cache; self must receive the
	// complete qualified basic projection instead of clearing MAIN fields.
	if s.Guilds == nil || s.Feedback == nil || s.Slots == nil || s.Content == nil {
		return nil, ErrProfileProvider
	}
	g, e := s.Guilds.ReadPublicGuildTx(c, sc, a.PlayerID, q.Target, rev, at)
	if e != nil {
		return nil, e
	}
	if g.PlayerID != q.Target || g.ContentRevision != rev || !g.ObservedAt.Equal(at) {
		return nil, ErrProfileProvider
	}
	info["guild_id"] = int64(g.GuildID)
	info["guild_name"] = g.Name
	info["guild_job"] = int16(g.Role)
	info["guild_invite_time"] = g.InviteTime
	info["title_info"] = display.TitleInfo
	out["open_functions"] = basic.Functions
	praise, e := s.Feedback.ObserveTx(c, sc, q.Target, a.PlayerID, rev, at)
	if e != nil {
		return nil, e
	}
	if praise.Actor != a.PlayerID || praise.Target != q.Target || praise.ContentRevision != rev || !praise.ObservedAt.Equal(at) || praise.Count < 0 || praise.RootVersion < 0 {
		return nil, ErrProfileProvider
	}
	out["praise_num"] = praise.Count
	out["is_has_praise"] = int64(0)
	if praise.HasPraised {
		out["is_has_praise"] = int64(1)
	}
	values, e := s.metrics(c, sc, q.Target, prefs.ShowTypeIDs, rev, at)
	if e != nil {
		return nil, e
	}
	out["show_types"] = values
	p, e := s.Content.ReadPublicShowcasePolicy(c, sc.Tx, rev)
	if e != nil || p.Validate() != nil || p.Revision != rev {
		return nil, ErrContent
	}
	selection, e := s.Slots.ReadSelectionTx(c, sc.Tx, q.Target)
	if e != nil {
		return nil, e
	}
	if !snapshot.Present && selection != (Selection{}) {
		return nil, ErrInvalidState
	}
	records, e := SlotRecordsTx(c, sc, ShowcaseSnapshot{PlayerID: q.Target, Selection: selection, RootVersion: basic.ProfileVersion, ContentRevision: rev, ObservedAt: at}, s.Records)
	if e != nil {
		return nil, e
	}
	if e = validateWireRecords(selection, records); e != nil {
		return nil, e
	}
	out["show_case"] = records
	if e = s.media(c, sc, q.Target, rev, at, out); e != nil {
		return nil, e
	}
	return out, nil
}
func (s ReadService) metrics(c context.Context, sc tx.Scope, pid identity.PlayerID, ids []int64, rev string, at time.Time) (map[string]int64, error) {
	if s.Metrics == nil {
		return nil, ErrProfileProvider
	}
	req := MetricRequest{PlayerID: pid, IDs: ids, ContentRevision: rev, ObservedAt: at}
	obs, e := readMetricsScopeTx(c, s.Metrics, sc, req)
	if e != nil {
		return nil, e
	}
	return metricValues(req, obs)
}
func (s ReadService) media(c context.Context, sc tx.Scope, pid identity.PlayerID, rev string, at time.Time, out map[string]any) error {
	if s.Media == nil {
		return ErrProfileProvider
	}
	h, ok, e := s.Basic.Roots.ReadMediaTx(c, sc, s.Media, pid, rev, at)
	if e != nil {
		return e
	}
	if ok {
		out["avatar_file_path"] = h.Reference.URL
		out["avatar_md5_code"] = h.Reference.Asset.MD5
	}
	return nil
}
func wireInteger(v any) (int64, bool) {
	raw, e := json.Marshal(v)
	if e != nil {
		return 0, false
	}
	n, e := strconv.ParseInt(string(raw), 10, 64)
	return n, e == nil && n >= -9007199254740991 && n <= 9007199254740991
}
func validateWireRecord(id int64, v map[string]any) error {
	if id == 0 {
		if v == nil || len(v) != 0 {
			return ErrShowcaseUnavailable
		}
		return nil
	}
	if len(v) == 0 {
		return ErrShowcaseUnavailable
	}
	key := "partner_id"
	want := id
	if id < 0 {
		key = "pet_id"
		want = -id
	}
	got, ok := wireInteger(v[key])
	if !ok || got != want {
		return ErrShowcaseUnavailable
	}
	table, ok := wireInteger(v["table_id"])
	if !ok || table <= 0 {
		return ErrShowcaseUnavailable
	}
	// Qualification of richer fields belongs to the actual typed providers;
	// identity validation alone is never a minimum-detail activation waiver.
	return nil
}
func validateWireRecords(q Selection, records [6]map[string]any) error {
	for i, id := range q {
		if e := validateWireRecord(id, records[i]); e != nil {
			return e
		}
	}
	return nil
}
