package characterasset

import (
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/character"
)

func syntheticProvenanceFixture(scope CoherentReadScope) SyntheticProfileProvenance {
	return SyntheticProfileProvenance{
		ProviderID:           "academy-arena",
		ProfileID:            "recruited-template",
		ProfileRevision:      "profile-v3",
		ContentRevision:      scope.ContentRevision,
		QualifiedOperationID: scope.Operation.ID,
		QualifiedAt:          scope.ObservedAt,
	}
}

func syntheticHeroBaseFixture() SyntheticHeroBase {
	return SyntheticHeroBase{
		TableID: 11001, OriginTableID: 11001, Kind: character.NormalHero,
		Star: 5, Level: 100, Exp: 0, Color: 16,
	}
}

func syntheticPetBaseFixture() SyntheticPetBase {
	return SyntheticPetBase{
		TableID: 21001, OriginTableID: 21001, Star: 5, Level: 100, Exp: 0, Color: 16,
		Skills: character.PetSkillLevels{90, 90, 70, 50, 30},
	}
}

func TestSyntheticHeroMaterializesBaseOnlyAndKeepsOriginsDistinct(t *testing.T) {
	scope := ca83CoherentScope(t)
	base := syntheticHeroBaseFixture()
	prov := syntheticProvenanceFixture(scope)

	trial, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "template:11001", Provenance: prov, Base: base,
	})
	if err != nil {
		t.Fatal(err)
	}
	if trial.Identity.Origin != ActorOriginTrial || trial.Identity.OperationID != scope.Operation.ID || trial.Identity.LocalKey != "template:11001" {
		t.Fatalf("unexpected trial identity: %+v", trial.Identity)
	}
	if trial.FeaturePayload != nil || trial.SourceLineage != nil {
		t.Fatalf("base-only profile gained optional state: %+v", trial)
	}
	if err := trial.Validate(); err != nil {
		t.Fatalf("valid trial projection rejected: %v", err)
	}

	npc, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
		Origin: ActorOriginNPCTemplate, LocalKey: "template:11001", Provenance: prov, Base: base,
	})
	if err != nil {
		t.Fatal(err)
	}
	if trial.Identity == npc.Identity {
		t.Fatal("TRIAL and NPC_TEMPLATE identities collided for the same operation/local key")
	}
	if npc.Identity.Origin != ActorOriginNPCTemplate || npc.Base != trial.Base {
		t.Fatalf("unexpected NPC projection: %+v", npc)
	}
}

func TestSyntheticLocalKeyIsOpaqueAndNotNormalized(t *testing.T) {
	scope := ca83CoherentScope(t)
	const key = "  zhuge:init_id=17  "
	out, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: key,
		Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(),
	})
	if err != nil {
		t.Fatal(err)
	}
	if out.Identity.LocalKey != key {
		t.Fatalf("opaque local key normalized: got %q want %q", out.Identity.LocalKey, key)
	}
}

func TestSyntheticHeroDefensivelyCopiesPayloadAndOwnedLineage(t *testing.T) {
	scope := ca83CoherentScope(t)
	payloadBytes := []byte{0x01, 0x02, 0x03, 0x04}
	payload := &SyntheticFeaturePayload{SchemaID: "academy.hero.character", SchemaRevision: "v1", Bytes: payloadBytes}
	owned := &character.HeroRef{PlayerID: 7, PartnerID: 41}
	lineage := &SyntheticHeroSourceLineage{OwnedRef: owned, StateVersion: 12}
	spec := QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "academy:slot:2",
		Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(),
		FeaturePayload: payload, SourceLineage: lineage,
	}

	first, err := MaterializeSyntheticHero(scope, spec)
	if err != nil {
		t.Fatal(err)
	}
	second, err := MaterializeSyntheticHero(scope, spec)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(first, second) {
		t.Fatalf("same scope/spec produced different projections:\nfirst=%+v\nsecond=%+v", first, second)
	}

	payloadBytes[0] = 0xff
	payload.Bytes[1] = 0xee
	owned.PartnerID = 999
	lineage.StateVersion = 999
	if got := first.FeaturePayload.Bytes; len(got) != 4 || got[0] != 0x01 || got[1] != 0x02 {
		t.Fatalf("materialized payload aliases caller buffer: %v", got)
	}
	if first.SourceLineage == nil || first.SourceLineage.OwnedRef == nil || first.SourceLineage.OwnedRef.PartnerID != 41 || first.SourceLineage.StateVersion != 12 {
		t.Fatalf("materialized lineage aliases caller state: %+v", first.SourceLineage)
	}
}

func TestSyntheticPetMaterializesTypedBasePayloadAndTemplateLineage(t *testing.T) {
	scope := ca83CoherentScope(t)
	prov := syntheticProvenanceFixture(scope)
	prov.ProviderID = "ragnarok"
	prov.ProfileID = "normalized-pet"
	payload := &SyntheticFeaturePayload{SchemaID: "ragnarok.pet.character", SchemaRevision: "v4", Bytes: []byte("canonical-pet-profile")}
	lineage := &SyntheticPetSourceLineage{TemplateID: 21001}

	out, err := MaterializeSyntheticPet(scope, QualifiedSyntheticPetSpec{
		Origin: ActorOriginNPCTemplate, LocalKey: "enemy-pet:3", Provenance: prov,
		Base: syntheticPetBaseFixture(), FeaturePayload: payload, SourceLineage: lineage,
	})
	if err != nil {
		t.Fatal(err)
	}
	if out.Identity.Origin != ActorOriginNPCTemplate || out.Base.Skills != (character.PetSkillLevels{90, 90, 70, 50, 30}) {
		t.Fatalf("unexpected Pet projection: %+v", out)
	}
	if out.SourceLineage == nil || out.SourceLineage.TemplateID != 21001 {
		t.Fatalf("template lineage lost: %+v", out.SourceLineage)
	}
	payload.Bytes[0] = 'X'
	lineage.TemplateID = 999
	if string(out.FeaturePayload.Bytes) != "canonical-pet-profile" || out.SourceLineage.TemplateID != 21001 {
		t.Fatal("Pet projection aliases caller payload/lineage")
	}
}

func TestSyntheticPetAllowsQualifiedProfileWithoutBaseSkills(t *testing.T) {
	scope := ca83CoherentScope(t)
	base := syntheticPetBaseFixture()
	base.Skills = character.PetSkillLevels{}
	if _, err := MaterializeSyntheticPet(scope, QualifiedSyntheticPetSpec{
		Origin: ActorOriginTrial, LocalKey: "pet:no-base-skills",
		Provenance: syntheticProvenanceFixture(scope), Base: base,
	}); err != nil {
		t.Fatalf("profile without typed base skills rejected: %v", err)
	}
}

func TestSyntheticMaterializersRejectOwnedBorrowedAndInvalidKeys(t *testing.T) {
	scope := ca83CoherentScope(t)
	for _, origin := range []ActorOrigin{ActorOriginOwned, ActorOriginBorrowed, ActorOrigin("UNKNOWN")} {
		_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
			Origin: origin, LocalKey: "x", Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(),
		})
		if !errors.Is(err, ErrInvalidSyntheticIdentity) {
			t.Fatalf("origin %q error=%v", origin, err)
		}
	}
	for _, key := range []string{"", " ", "\t\n", strings.Repeat("x", maxSyntheticLocalKeyBytes+1)} {
		_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
			Origin: ActorOriginTrial, LocalKey: key, Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(),
		})
		if !errors.Is(err, ErrInvalidSyntheticIdentity) {
			t.Fatalf("key %q error=%v", key, err)
		}
	}
}

func TestSyntheticProfileProvenanceRequiresExactCallerScope(t *testing.T) {
	scope := ca83CoherentScope(t)
	valid := syntheticProvenanceFixture(scope)

	invalid := []SyntheticProfileProvenance{}
	p := valid
	p.ProviderID = " "
	invalid = append(invalid, p)
	p = valid
	p.ProfileID = "\t"
	invalid = append(invalid, p)
	p = valid
	p.ProfileRevision = "\n"
	invalid = append(invalid, p)
	p = valid
	p.ContentRevision = strings.Repeat("c", 63)
	invalid = append(invalid, p)
	p = valid
	p.QualifiedOperationID = [16]byte{}
	invalid = append(invalid, p)
	p = valid
	p.QualifiedAt = time.Time{}
	invalid = append(invalid, p)
	p = valid
	p.QualifiedAt = time.Unix(50, 0).In(time.FixedZone("not-UTC-object", 0))
	invalid = append(invalid, p)

	for i, prov := range invalid {
		_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
			Origin: ActorOriginTrial, LocalKey: "x", Provenance: prov, Base: syntheticHeroBaseFixture(),
		})
		if !errors.Is(err, ErrInvalidSyntheticProvenance) {
			t.Fatalf("invalid provenance case %d error=%v", i, err)
		}
	}

	mismatch := valid
	mismatch.ContentRevision = strings.Repeat("c", 64)
	_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "x", Provenance: mismatch, Base: syntheticHeroBaseFixture(),
	})
	if !errors.Is(err, ErrSyntheticScopeMismatch) {
		t.Fatalf("content mismatch error=%v", err)
	}

	mismatch = valid
	mismatch.QualifiedOperationID[0] ^= 0xff
	_, err = MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "x", Provenance: mismatch, Base: syntheticHeroBaseFixture(),
	})
	if !errors.Is(err, ErrSyntheticScopeMismatch) {
		t.Fatalf("operation mismatch error=%v", err)
	}

	mismatch = valid
	mismatch.QualifiedAt = mismatch.QualifiedAt.Add(time.Second)
	_, err = MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
		Origin: ActorOriginTrial, LocalKey: "x", Provenance: mismatch, Base: syntheticHeroBaseFixture(),
	})
	if !errors.Is(err, ErrSyntheticScopeMismatch) {
		t.Fatalf("time mismatch error=%v", err)
	}
}

func TestSyntheticHeroBaseFailsClosed(t *testing.T) {
	scope := ca83CoherentScope(t)
	base := syntheticHeroBaseFixture()
	mutations := []func(*SyntheticHeroBase){
		func(b *SyntheticHeroBase) { b.TableID = 0 },
		func(b *SyntheticHeroBase) { b.OriginTableID = 0 },
		func(b *SyntheticHeroBase) { b.Kind = character.HeroKind("?") },
		func(b *SyntheticHeroBase) { b.Star = 0 },
		func(b *SyntheticHeroBase) { b.Star = character.MaxHeroStar + 1 },
		func(b *SyntheticHeroBase) { b.Level = 0 },
		func(b *SyntheticHeroBase) { b.Exp = -1 },
		func(b *SyntheticHeroBase) { b.Color = 0 },
		func(b *SyntheticHeroBase) { b.Color = 17 },
	}
	for i, mutate := range mutations {
		bad := base
		mutate(&bad)
		_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
			Origin: ActorOriginTrial, LocalKey: "x", Provenance: syntheticProvenanceFixture(scope), Base: bad,
		})
		if !errors.Is(err, ErrInvalidSyntheticHeroBase) {
			t.Fatalf("Hero base case %d error=%v", i, err)
		}
	}
}

func TestSyntheticPetBaseFailsClosed(t *testing.T) {
	scope := ca83CoherentScope(t)
	base := syntheticPetBaseFixture()
	mutations := []func(*SyntheticPetBase){
		func(b *SyntheticPetBase) { b.TableID = 0 },
		func(b *SyntheticPetBase) { b.OriginTableID = 0 },
		func(b *SyntheticPetBase) { b.Star = 0 },
		func(b *SyntheticPetBase) { b.Star = character.MaxPetStar + 1 },
		func(b *SyntheticPetBase) { b.Level = 0 },
		func(b *SyntheticPetBase) { b.Exp = -1 },
		func(b *SyntheticPetBase) { b.Color = 17 },
		func(b *SyntheticPetBase) { b.Skills = character.PetSkillLevels{1, 1, 0, 1, 1} },
	}
	for i, mutate := range mutations {
		bad := base
		mutate(&bad)
		_, err := MaterializeSyntheticPet(scope, QualifiedSyntheticPetSpec{
			Origin: ActorOriginTrial, LocalKey: "x", Provenance: syntheticProvenanceFixture(scope), Base: bad,
		})
		if !errors.Is(err, ErrInvalidSyntheticPetBase) {
			t.Fatalf("Pet base case %d error=%v", i, err)
		}
	}
}

func TestSyntheticPayloadAndLineageFailClosed(t *testing.T) {
	scope := ca83CoherentScope(t)
	for i, payload := range []*SyntheticFeaturePayload{
		{SchemaID: "", SchemaRevision: "v1", Bytes: []byte{1}},
		{SchemaID: "schema", SchemaRevision: " ", Bytes: []byte{1}},
		{SchemaID: "schema", SchemaRevision: "v1", Bytes: nil},
	} {
		_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
			Origin: ActorOriginTrial, LocalKey: "x", Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(), FeaturePayload: payload,
		})
		if !errors.Is(err, ErrInvalidSyntheticPayload) {
			t.Fatalf("payload case %d error=%v", i, err)
		}
	}

	badHeroRefs := []*SyntheticHeroSourceLineage{
		{},
		{OwnedRef: &character.HeroRef{PlayerID: 1, PartnerID: 2}, StateVersion: 0},
		{OwnedRef: &character.HeroRef{PlayerID: 1, PartnerID: 2}, StateVersion: 1, TemplateID: 11001},
		{TemplateID: 11001, StateVersion: 1},
	}
	for i, lineage := range badHeroRefs {
		_, err := MaterializeSyntheticHero(scope, QualifiedSyntheticHeroSpec{
			Origin: ActorOriginTrial, LocalKey: "x", Provenance: syntheticProvenanceFixture(scope), Base: syntheticHeroBaseFixture(), SourceLineage: lineage,
		})
		if !errors.Is(err, ErrInvalidSyntheticLineage) {
			t.Fatalf("Hero lineage case %d error=%v", i, err)
		}
	}

	badPetRefs := []*SyntheticPetSourceLineage{
		{},
		{OwnedRef: &character.PetRef{PlayerID: 1, PetID: 2}, StateVersion: -1},
		{OwnedRef: &character.PetRef{PlayerID: 0, PetID: 2}, StateVersion: 1},
		{TemplateID: -1},
	}
	for i, lineage := range badPetRefs {
		_, err := MaterializeSyntheticPet(scope, QualifiedSyntheticPetSpec{
			Origin: ActorOriginTrial, LocalKey: "x", Provenance: syntheticProvenanceFixture(scope), Base: syntheticPetBaseFixture(), SourceLineage: lineage,
		})
		if !errors.Is(err, ErrInvalidSyntheticLineage) {
			t.Fatalf("Pet lineage case %d error=%v", i, err)
		}
	}
}

func TestSyntheticMaterializerRejectsInvalidCoherentScopeBeforeSpec(t *testing.T) {
	_, err := MaterializeSyntheticHero(CoherentReadScope{}, QualifiedSyntheticHeroSpec{})
	if !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("Hero invalid scope error=%v", err)
	}
	_, err = MaterializeSyntheticPet(CoherentReadScope{}, QualifiedSyntheticPetSpec{})
	if !errors.Is(err, ErrInvalidCoherentReadScope) {
		t.Fatalf("Pet invalid scope error=%v", err)
	}
}
