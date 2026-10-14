package contentstore

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/contentqueries"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
	"time"
)

type tag int64

func (t tag) RowsAffected() int64 { return int64(t) }

type recording struct {
	bySQL    map[string][]any
	calls    []string
	callArgs [][]any
	sql      string
	args     []any
	values   []any
	n        int64
	err      error
}

func (r *recording) QueryRow(_ context.Context, sql string, args ...any) tx.Row {
	r.sql = sql
	r.args = args
	r.calls = append(r.calls, sql)
	r.callArgs = append(r.callArgs, args)
	return r
}
func (r *recording) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}
	values := r.values
	if v, ok := r.bySQL[r.sql]; ok {
		values = v
	}
	if len(dest) != len(values) {
		return errors.New("scan arity")
	}
	for i, v := range values {
		reflect.ValueOf(dest[i]).Elem().Set(reflect.ValueOf(v))
	}
	return nil
}
func (r *recording) Exec(_ context.Context, sql string, args ...any) (tx.CommandTag, error) {
	r.sql = sql
	r.args = args
	return tag(r.n), r.err
}
func (r *recording) Commit(context.Context) error   { return errors.New("store must not commit") }
func (r *recording) Rollback(context.Context) error { return errors.New("store must not rollback") }
func TestBundleQueriesUseExactRawBytes(t *testing.T) {
	ctx := context.Background()
	s := Store{}
	b, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	q := &recording{values: []any{true}}
	if ok, err := s.TryInsertRevision(ctx, q, b); err != nil || !ok {
		t.Fatal(ok, err)
	}
	if q.sql != contentqueries.TryInsertContentRevision || q.args[4] != string(b.ManifestJSON()) {
		t.Fatal("manifest reserialized")
	}
	cases := []struct {
		call func(context.Context, tx.Tx, registry.Bundle) (int64, error)
		sql  string
		raw  []byte
		n    int64
	}{{s.InsertResources, contentqueries.InsertContentResources, b.ResourcesJSON(), 5557}, {s.InsertProgression, contentqueries.InsertContentPlayerProgression, b.ProgressionJSON(), 100}, {s.InsertFunctionGates, contentqueries.InsertContentFunctionGates, b.FunctionGatesJSON(), 99}, {s.InsertObjectives, contentqueries.InsertContentObjectives, b.ObjectivesJSON(), 0}, {s.InsertHeroCore, contentqueries.InsertContentHeroCore, b.HeroCoreJSON(), 568}, {s.InsertPetCore, contentqueries.InsertContentPetCore, b.PetCoreJSON(), 54}, {s.InsertPetAcquisition, contentqueries.InsertContentPetAcquisition, b.PetAcquisitionJSON(), 27}, {s.InsertPetProgression, contentqueries.InsertContentPetProgression, b.PetProgressionJSON(), 54}, {s.InsertEquipmentPrimitives, contentqueries.InsertContentEquipmentPrimitives, b.EquipmentPrimitivesJSON(), 1176}, {s.InsertHeroEquipment, contentqueries.InsertContentHeroEquipment, b.HeroEquipmentJSON(), 53280}, {s.InsertSuperEquipment, contentqueries.InsertContentSuperEquipment, b.SuperEquipmentJSON(), 84}, {s.InsertPetEquipment, contentqueries.InsertContentPetEquipment, b.PetEquipmentJSON(), 2592}, {s.InsertPetPromotionRestoration, contentqueries.InsertContentPetPromotionRestoration, b.PetPromotionRestorationJSON(), 73}, {s.InsertPractice, contentqueries.InsertContentPractice, b.PracticeJSON(), 1889}, {s.InsertAppearance, contentqueries.InsertContentAppearance, b.AppearanceJSON(), 542}, {s.InsertEmoticons, contentqueries.InsertContentEmoticons, b.EmoticonsJSON(), 85}}
	for _, c := range cases {
		q.values = []any{c.n}
		if got, err := c.call(ctx, q, b); err != nil || got != c.n {
			t.Fatal(got, err)
		}
		if q.sql != c.sql || !reflect.DeepEqual(q.args, []any{b.RevisionID(), string(c.raw)}) {
			t.Fatal("query input mismatch")
		}
	}
	q.values = []any{int64(359), int64(516)}
	if targets, materials, err := s.InsertHeroFumo(ctx, q, b); err != nil || targets != 359 || materials != 516 {
		t.Fatal(targets, materials, err)
	}
	if q.sql != contentqueries.InsertContentHeroFumo || !reflect.DeepEqual(q.args, []any{b.RevisionID(), string(b.HeroFumoJSON())}) {
		t.Fatal("Hero Fumo query input mismatch")
	}
	q.values = []any{int64(195), int64(5), int64(3)}
	if equipment, fractions, denominations, err := s.InsertHeroPromotionRestoration(ctx, q, b); err != nil || equipment != 195 || fractions != 5 || denominations != 3 {
		t.Fatal(equipment, fractions, denominations, err)
	}
	if q.sql != contentqueries.InsertContentHeroPromotionRestoration || !reflect.DeepEqual(q.args, []any{b.RevisionID(), string(b.HeroPromotionRestorationJSON())}) {
		t.Fatal("Hero promotion restoration query input mismatch")
	}
	q.values = []any{true, int64(5561), int64(100), int64(99), int64(0), int64(568), int64(54), int64(27), int64(54), int64(1176), int64(53280), int64(84), int64(359), int64(516), int64(195), int64(5), int64(3), int64(2592), int64(73), int64(1889), int64(542)}
	q.bySQL = map[string][]any{verifyCourseInputsSQL: {true, int64(1)}, verifyBookInputsSQL: {true, int64(1)}, verifyDormInputsSQL: {true, int64(1)}, verifyLibraryInputsSQL: {true, int64(1)}, verifyPlayerDisplaySQL: {true, int64(1)}, contentqueries.VerifyContentEmoticons: {true, int64(85)}, verifySocialGiftSQL: {true}, verifyGuildBroadcastSQL: {true, int64(1)}, verifyGuildInviteSQL: {true, int64(1)}, verifyPublicProfileSQL: {true, int64(1)}, verifyPublicShowcaseSQL: {true, int64(1)}}
	v, err := s.VerifyRevision(ctx, q, b)
	if err != nil || !v.Matches(b) || q.calls[len(q.calls)-11] != contentqueries.VerifyContentRevision || len(q.callArgs[len(q.callArgs)-11]) != 22 || q.calls[len(q.calls)-5] != verifyPublicProfileSQL || !reflect.DeepEqual(q.callArgs[len(q.callArgs)-5], []any{b.RevisionID(), string(b.PublicProfileJSON())}) || q.sql != verifyGuildInviteSQL || !reflect.DeepEqual(q.args, []any{b.RevisionID(), string(b.GuildInviteJSON())}) || v.PublicProfileCount != 1 || v.GuildBroadcastCount != 1 || v.EmoticonCount != 85 {
		t.Fatal(v, err)
	}
}
func TestActivationCASAndBootstrapRows(t *testing.T) {
	s := Store{}
	ctx := context.Background()
	q := &recording{n: 1}
	at := time.Date(2026, 1, 1, 0, 0, 0, 0, time.FixedZone("x", 3600))
	e := registry.ActivationIdentity{RevisionID: "old", Version: 4}
	if ok, err := s.ActivateCAS(ctx, q, "target", at, "host", e); err != nil || !ok {
		t.Fatal(ok, err)
	}
	if q.sql != contentqueries.ActivateContentCAS || !reflect.DeepEqual(q.args, []any{"target", at.UTC(), "host", "old", int64(4)}) {
		t.Fatal(q.args)
	}
	for _, n := range []int64{0, 1, 2} {
		q.n = n
		ok, err := s.BootstrapActivation(ctx, q, "target", at, "actor")
		if (err != nil) != (n == 2) || ok != (n == 1) {
			t.Fatal(n, ok, err)
		}
	}
}
func TestAbsentReadAndDatabaseError(t *testing.T) {
	s := Store{}
	ctx := context.Background()
	q := &recording{values: []any{false, "", int64(0), time.Time{}, ""}}
	if _, ok, err := s.ReadActivation(ctx, q); err != nil || ok {
		t.Fatal(ok, err)
	}
	q.err = errors.New("db failure")
	if _, _, err := s.ReadActiveSummary(ctx, q); err == nil {
		t.Fatal("lost database error")
	}
	if err := s.LockRegistry(ctx, nil); err == nil {
		t.Fatal("nil transaction")
	}
}

func TestR4DActiveRevisionAndExactResourceReads(t *testing.T) {
	ctx := context.Background()
	revision := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	q := &recording{values: []any{true, revision, int64(7), time.Unix(10, 0).UTC(), "operator"}}
	s := Store{}
	got, err := s.ActiveRevision(ctx, q)
	if err != nil || got != revision {
		t.Fatalf("active revision got=%q err=%v", got, err)
	}
	if q.sql != contentqueries.ReadContentActivation {
		t.Fatalf("active revision used unexpected query: %s", q.sql)
	}

	q = &recording{values: []any{
		string(grant.ScalarCurrency), "FOUNDATION_READY", "ENABLED_R4", "mana", int64(0),
		int64(0), false, int64(0), int64(0), "", int64(0), "", "",
	}}
	policy, err := s.ResolveResourceTx(ctx, q, revision, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 5})
	if err != nil {
		t.Fatal(err)
	}
	if policy.Kind != grant.ScalarCurrency || policy.PolicyVersion != revision {
		t.Fatalf("unexpected scalar policy: %+v", policy)
	}
	if q.sql != contentqueries.ReadContentResourceByResourceKey || !reflect.DeepEqual(q.args, []any{revision, string(grant.ScalarCurrency), "mana"}) {
		t.Fatalf("scalar lookup not exact-revision qualified: sql=%q args=%v", q.sql, q.args)
	}

	q = &recording{values: []any{
		string(grant.StackItem), "FOUNDATION_READY", "ENABLED_R4", "", int64(42),
		int64(999), true, int64(0), int64(0), "", int64(0), "", "",
	}}
	policy, err = s.ResolveResourceTx(ctx, q, revision, grant.Line{Kind: grant.StackItem, ItemID: 42, Amount: 2})
	if err != nil {
		t.Fatal(err)
	}
	if policy.Stack == nil || policy.Stack.ItemID != 42 || policy.Stack.StackCap != 999 || !policy.Stack.OverflowToMail || policy.PolicyVersion != revision {
		t.Fatalf("unexpected stack policy: %+v", policy)
	}
	if q.sql != contentqueries.ReadContentResourceByItemID || !reflect.DeepEqual(q.args, []any{revision, int64(42)}) {
		t.Fatalf("stack lookup not exact-revision qualified: sql=%q args=%v", q.sql, q.args)
	}

	q = &recording{values: []any{
		string(grant.Temporal), "FOUNDATION_READY", "ENABLED_R4", "energy", int64(0),
		int64(0), false, int64(300), int64(1), "NATURAL_CAP", int64(100), "", "",
	}}
	if _, err := s.ResolveResourceTx(ctx, q, revision, grant.Line{Kind: grant.Temporal, ResourceKey: "energy", Amount: 1}); !errors.Is(err, economy.ErrUnknownResource) {
		t.Fatalf("R5-gated temporal content must fail closed, got %v", err)
	}
	if q.sql != contentqueries.ReadContentResourceByResourceKey || !reflect.DeepEqual(q.args, []any{revision, string(grant.Temporal), "energy"}) {
		t.Fatalf("temporal lookup must still be exact-revision qualified before fail-closed gate: %v", q.args)
	}
}

func TestR4DResolveObjectiveUsesExactRevisionTuple(t *testing.T) {
	ctx := context.Background()
	revision := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
	plan := grant.Plan{
		PlayerID: identity.PlayerID(100001),
		Source:   grant.SourceIdentity{Domain: "objective", Operation: "claim", BusinessKey: "daily:161", Occurrence: "g1", PolicyVersion: "legacy-definition-v1"},
		Lines:    []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 10}},
	}
	raw, err := json.Marshal(plan)
	if err != nil {
		t.Fatal(err)
	}
	q := &recording{values: []any{int64(objective.Daily), "HIGH_WATER", "level", int64(10), string(raw), int64(5)}}
	s := Store{}
	got, err := s.ResolveObjectiveTx(ctx, q, revision, "daily", 161, "def-r1")
	if err != nil {
		t.Fatal(err)
	}
	if got.Family != objective.Daily || got.Definition.ProgramID != "daily" || got.Definition.ObjectiveID != 161 || got.Definition.DefinitionRevision != "def-r1" || got.Reward.PlayerID != plan.PlayerID {
		t.Fatalf("unexpected objective definition: %+v", got)
	}
	if q.sql != contentqueries.ReadContentObjectiveDefinition || !reflect.DeepEqual(q.args, []any{revision, "daily", int64(161), "def-r1"}) {
		t.Fatalf("objective lookup not exact-revision qualified: sql=%q args=%v", q.sql, q.args)
	}
}

func TestR5ExactProgressionFunctionAndTemporalReads(t *testing.T) {
	ctx := context.Background()
	revision := "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
	s := Store{}

	progressionJSON := `[{"level":1,"max_energy":60,"award_energy":5,"total_exp":6},{"level":2,"max_energy":70,"award_energy":0,"total_exp":20}]`
	q := &recording{values: []any{progressionJSON}}
	pp, err := s.ResolveProgressionPolicyTx(ctx, q, revision)
	if err != nil {
		t.Fatal(err)
	}
	if pp.Revision != revision || len(pp.Rows) != 2 || pp.Rows[0].MaxEnergy != 60 || pp.Rows[1].TotalExp != 20 {
		t.Fatalf("progression=%+v", pp)
	}
	if q.sql != contentqueries.ReadContentPlayerProgressionPolicy || !reflect.DeepEqual(q.args, []any{revision}) {
		t.Fatalf("progression lookup not exact revision: sql=%q args=%v", q.sql, q.args)
	}

	functionJSON := `[{"function_id":33,"gate_kind":"PURE_LEVEL","required_level":7,"raw_open_value":"1|7","source_fact_key":"function:33","announcement_capability":"SKILL_GUIDE"},{"function_id":45,"gate_kind":"UNSUPPORTED_COMPOSITE","required_level":null,"raw_open_value":"7|100","source_fact_key":"function:45","announcement_capability":"BLOOD_AWAKEN"}]`
	q = &recording{values: []any{functionJSON}}
	fp, err := s.ResolveFunctionGatePolicyTx(ctx, q, revision)
	if err != nil {
		t.Fatal(err)
	}
	if fp.Revision != revision || len(fp.Gates) != 2 || fp.Gates[0].FunctionID != 33 || fp.Gates[0].RequiredLevel != 7 || fp.Gates[1].RequiredLevel != 0 {
		t.Fatalf("function policy=%+v", fp)
	}
	if q.sql != contentqueries.ReadContentFunctionGatePolicy || !reflect.DeepEqual(q.args, []any{revision}) {
		t.Fatalf("function lookup not exact revision: sql=%q args=%v", q.sql, q.args)
	}

	q = &recording{values: []any{
		string(grant.Temporal), "QUALIFIED", "ENABLED_R5", "energy", int64(0),
		int64(0), false, int64(300), int64(1), "PLAYER_LEVEL_ENERGY", int64(0), "", "",
	}}
	rp, err := s.ResolveResourceTx(ctx, q, revision, grant.Line{Kind: grant.Temporal, ResourceKey: "energy", Amount: 1})
	if err != nil {
		t.Fatal(err)
	}
	if rp.Descriptor == nil || rp.Descriptor.Revision != revision || rp.Descriptor.ResourceKey != "energy" || rp.Descriptor.RegenEvery != 300*time.Second || rp.Descriptor.CapRule != "PLAYER_LEVEL_ENERGY" {
		t.Fatalf("temporal descriptor=%+v", rp.Descriptor)
	}
	if q.sql != contentqueries.ReadContentResourceByResourceKey || !reflect.DeepEqual(q.args, []any{revision, string(grant.Temporal), "energy"}) {
		t.Fatalf("temporal lookup not exact revision: sql=%q args=%v", q.sql, q.args)
	}
}

func TestHeroKindUsesExactRevisionAndTable(t *testing.T) {
	ctx := context.Background()
	revision := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	q := &recording{values: []any{"SUPER"}}
	k, err := (Store{Queryer: q}).HeroKind(ctx, revision, 12000001)
	if err != nil || k != "SUPER" {
		t.Fatalf("kind=%q err=%v", k, err)
	}
	if q.sql != contentqueries.ReadHeroTemplateKind || !reflect.DeepEqual(q.args, []any{revision, int64(12000001)}) {
		t.Fatalf("Hero kind lookup not exact-revision qualified: sql=%q args=%v", q.sql, q.args)
	}
}
