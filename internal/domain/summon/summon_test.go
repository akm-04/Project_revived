package summon

import (
	"encoding/json"
	"errors"
	"os"
	"testing"
)

type fixed struct{ values []uint64 }

func (f *fixed) Uniform(n uint64) uint64 {
	if len(f.values) == 0 {
		return n - 1
	}
	v := f.values[0]
	f.values = f.values[1:]
	return v % n
}

func load(t *testing.T) *Catalog {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/summon_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var c Catalog
	if err = json.Unmarshal(raw, &c); err != nil {
		t.Fatal(err)
	}
	if err = c.Validate(); err != nil {
		t.Fatal(err)
	}
	return &c
}

func button(t *testing.T, c *Catalog, kind, index int64) Button {
	b, ok := c.Button(kind, index)
	if !ok {
		t.Fatalf("button %d/%d", kind, index)
	}
	return b
}

func TestFirstFreeSlotsAreTheTutorialGirls(t *testing.T) {
	c := load(t)
	s := c.NewState(1)
	slots, s, err := c.Draw(button(t, c, 1, 1), s, 0, &fixed{})
	if err != nil || len(slots) != 1 || slots[0].ItemID != 10001002 || !slots[0].Special || s.Counters[Small] != 1 {
		t.Fatal(slots, s, err)
	}
	slots, s, err = c.Draw(button(t, c, 3, 1), s, 0, &fixed{})
	if err != nil || len(slots) != 1 || slots[0].ItemID != 10001003 || s.Counters[MediumFree] != 1 || s.Counters[Small] != 1 {
		t.Fatal(slots, s, err)
	}
}

func TestFreeTimersAndDailyRefill(t *testing.T) {
	c := load(t)
	small, medium, paid := button(t, c, 1, 1), button(t, c, 3, 1), button(t, c, 1, 2)
	s := c.NewState(10)
	s, err := c.Admit(small, s, 1000, 10)
	if err != nil || s.ManaFreeNum != 4 || s.ManaFreeTime != 1000 {
		t.Fatal(s, err)
	}
	if _, err = c.Admit(small, s, 1599, 10); !errors.Is(err, ErrRefused) {
		t.Fatal("Small free before 600 s", err)
	}
	s.ManaFreeNum = 0
	if _, err = c.Admit(small, s, 5000, 10); !errors.Is(err, ErrRefused) {
		t.Fatal("Small free without count", err)
	}
	if s, err = c.Admit(small, s, 5000, 11); err != nil || s.ManaFreeNum != 4 || s.ManaFreeDay != 11 {
		t.Fatal("D140 refill", s, err)
	}
	if s, err = c.Admit(medium, s, 5000, 11); err != nil || s.CrystalFreeTime != 5000 {
		t.Fatal(s, err)
	}
	if _, err = c.Admit(medium, s, 5000+165599, 11); !errors.Is(err, ErrRefused) {
		t.Fatal("Medium free before 46 h", err)
	}
	if got, err := c.Admit(paid, s, 5001, 11); err != nil || got.ManaFreeNum != s.ManaFreeNum {
		t.Fatal("paid button touched the free state", got, err)
	}
}

func TestMediumFeaturedPityForcesTheTwentiethSlot(t *testing.T) {
	c := load(t)
	b := button(t, c, 2, 1)
	featured := c.Policy.Cohorts.MediumFeatured[0]
	s := c.NewState(1)
	s.Counters[MediumPaid] = 11
	s.FeaturedTarget, s.FeaturedPity = featured, 18
	slots, s, err := c.Draw(b, s, featured, &fixed{values: []uint64{9999, 9999, 0}})
	if err != nil || slots[0].ItemID == featured || s.FeaturedPity != 19 {
		t.Fatal(slots, s, err)
	}
	slots, s, err = c.Draw(b, s, featured, &fixed{values: []uint64{9999}})
	if err != nil || slots[0].ItemID != featured || s.FeaturedPity != 0 {
		t.Fatal("pity slot", slots, s, err)
	}
	other := c.Policy.Cohorts.MediumFeatured[1]
	s.FeaturedPity = 7
	if _, s, _ = c.Draw(b, s, other, &fixed{values: []uint64{9999, 9999, 0}}); s.FeaturedTarget != other || s.FeaturedPity != 1 {
		t.Fatal("target change resets pity", s)
	}
}

func TestTenPullBlocksHoldTheGuaranteedKind(t *testing.T) {
	c := load(t)
	s := c.NewState(1)
	s.Counters[Small] = 400
	slots, _, err := c.Draw(button(t, c, 1, 4), s, 0, &fixed{})
	if err != nil || len(slots) != 100 {
		t.Fatal(len(slots), err)
	}
	for start := 0; start < 100; start += 10 {
		found := false
		for _, slot := range slots[start : start+10] {
			found = found || slot.Kind == ItemKind
		}
		if !found {
			t.Fatal("Small block without an item", start)
		}
	}
	s.Counters[MediumPaid] = 11
	s.FeaturedTarget, s.FeaturedPity = 1, 0
	featured := c.Policy.Cohorts.MediumFeatured[0]
	values := make([]uint64, 0, 40)
	for i := 0; i < 10; i++ {
		values = append(values, 9999, 9999, 0)
	}
	slots, _, err = c.Draw(button(t, c, 2, 2), s, featured, &fixed{values: values})
	if err != nil || slots[9].Kind != HeroKind {
		t.Fatal("Medium ten without a hero", slots, err)
	}
	for _, slot := range slots[:9] {
		if slot.Kind != ItemKind {
			t.Fatal("ordinary slot changed", slots)
		}
	}
}

func TestDuplicatesAndRotation(t *testing.T) {
	c := load(t)
	if got, err := c.Fragments(10001002); err != nil || got[1] != 7 {
		t.Fatal(got, err)
	}
	r := c.Rotation(500)
	again := c.Rotation(500)
	if len(r.Main) != 2 || len(r.Second) != 3 || r.Partner != again.Partner || r.Main[0] != again.Main[0] || r.Second[2] != again.Second[2] {
		t.Fatal(r, again)
	}
	seen := map[int64]bool{}
	for _, id := range append(append([]int64(nil), r.Main...), r.Second...) {
		if seen[id] {
			t.Fatal("duplicate featured SX", r)
		}
		seen[id] = true
	}
	if c.Rotation(497).Main[0] != c.Rotation(503).Main[0] || c.Rotation(497).Main[1] != c.Rotation(503).Main[1] {
		t.Fatal("SX main ids must hold for a 7-day block")
	}
}

func TestOperatorTuning(t *testing.T) {
	c := load(t)
	sx := c.Policy.Cohorts.SX
	tuned, err := c.Tune(Tuning{Version: 1, MediumSuperChance: 2000, FeaturedPity: 5, Partner: c.Policy.Cohorts.MediumFeatured[3], Main: sx[:2], Second: sx[2:5]})
	if err != nil || tuned.Policy.Classic.Medium.SuperChance != 2000 || tuned.Policy.Classic.Small.SuperChance != c.Policy.Classic.Small.SuperChance || tuned.Policy.Classic.MediumFeatured.Pity != 5 {
		t.Fatal(tuned.Policy.Classic, err)
	}
	r := tuned.Rotation(42)
	if r.Partner != c.Policy.Cohorts.MediumFeatured[3] || r.Main[1] != sx[1] || r.Second[2] != sx[4] {
		t.Fatal("pins", r)
	}
	if c.Rotation(42).Partner == 0 || c.Policy.Classic.Medium.SuperChance == 2000 {
		t.Fatal("tuning leaked into the source catalog")
	}
	for _, bad := range []Tuning{{FeaturedChance: 10001}, {Partner: 50001002}, {Main: sx[:1]}, {Second: []int64{10001002, sx[0], sx[1]}, Main: sx[2:4]}} {
		if _, err := c.Tune(bad); err == nil {
			t.Fatal("accepted", bad)
		}
	}
}

func TestShowcaseRotatesApartFromTheRateUpAndJuicePerPull(t *testing.T) {
	c := load(t)
	pets := map[int64]bool{}
	for day := int64(400); day < 430; day++ {
		r := c.Rotation(day)
		if r.Pet == 0 || r.Pet == r.Partner {
			t.Fatal("showcase must be a featured girl other than the rate-up", day, r)
		}
		pets[r.Pet] = true
	}
	if len(pets) < 5 {
		t.Fatal("showcase does not rotate", pets)
	}
	pinned := c.Policy.Cohorts.MediumFeatured[2]
	tuned, err := c.Tune(Tuning{Pet: pinned, Partner: c.Policy.Cohorts.MediumFeatured[3]})
	if err != nil || tuned.Rotation(9).Pet != pinned {
		t.Fatal("showcase pin", err)
	}

	small, _ := c.Button(1, 4)
	sx, _ := c.Button(4, 1)
	magicTen, _ := c.Button(33, 2)
	for _, want := range []struct {
		b            Button
		item, amount int64
	}{{small, 50001002, 100}, {sx, 50001005, 1}, {magicTen, 50005182, 10}} {
		if item, amount := c.Juice(want.b); item != want.item || amount != want.amount {
			t.Fatal("juice", want.b, item, amount)
		}
	}
	zero := int64(0)
	off, err := c.Tune(Tuning{JuicePerPull: &zero})
	if _, amount := off.Juice(small); err != nil || amount != 0 {
		t.Fatal("operator juice off", amount, err)
	}
	flood := int64(maxJuicePerPull + 1)
	if _, err = c.Tune(Tuning{JuicePerPull: &flood}); err == nil {
		t.Fatal("unbounded juice accepted")
	}
}
