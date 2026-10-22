package combatresolver

import (
	"regexp"
	"sort"
	"strings"
	"testing"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/combat"
)

var populateHeader = regexp.MustCompile(`^function var_0_\d+\.populate_?\(arg_\d+_0, (arg_\d+_1)`)

// populateReadSet returns every params key a corpus model's populate reads.
func populateReadSet(t *testing.T, corpus *combatcorpus.Corpus, module string) map[string]bool {
	t.Helper()
	source, ok := corpus.Module(module)
	if !ok {
		t.Fatal("corpus module missing", module)
	}
	keys := map[string]bool{}
	lines := strings.Split(source, "\n")
	for start, line := range lines {
		header := populateHeader.FindStringSubmatch(line)
		if header == nil {
			continue
		}
		end := start + 1
		for end < len(lines) && !strings.HasPrefix(lines[end], "function ") && lines[end] != "end" {
			end++
		}
		access := regexp.MustCompile(regexp.QuoteMeta(header[1]) + `(?:\.([A-Za-z_][A-Za-z0-9_]*)|\["([^"]+)"\])`)
		for _, match := range access.FindAllStringSubmatch(strings.Join(lines[start:end+1], "\n"), -1) {
			keys[match[1]+match[2]] = true
		}
	}
	if len(keys) == 0 {
		t.Fatal("no populate found in", module)
	}
	return keys
}

func sortedKeys[V any](set map[string]V) []string {
	keys := make([]string, 0, len(set))
	for key := range set {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

// TestProducerRegistryCoversPopulateKeys is the I8-3A static key audit: every
// key the stock populate reads has exactly one registered producer and the
// registry names no key the stock client never reads.
func TestProducerRegistryCoversPopulateKeys(t *testing.T) {
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	heroReads := populateReadSet(t, corpus, "app.model.NormalHero")
	for key := range populateReadSet(t, corpus, "app.model.SuperHero") {
		heroReads[key] = true
	}
	profile, _ := combat.LookupProducerProfile(combat.ProducerProfileID)
	kinds := map[combat.ActorKind]map[string]bool{combat.HeroActor: heroReads, combat.PetActor: populateReadSet(t, corpus, "app.model.Pet")}
	for kind, reads := range kinds {
		registered := profile.Keys(kind)
		if got, want := strings.Join(sortedKeys(registered), ","), strings.Join(sortedKeys(reads), ","); got != want {
			t.Fatalf("%s registry keys\n got %s\nwant %s", kind, got, want)
		}
		owners := map[string]string{}
		for _, producer := range profile.Producers {
			for _, key := range producer.KeysFor(kind) {
				if owner, taken := owners[key]; taken {
					t.Fatalf("%s key %s owned by %s and %s", kind, key, owner, producer.ID)
				}
				owners[key] = producer.ID
			}
		}
	}
}
