package librarylocal

import (
	"reflect"
	"testing"
)

func TestHeroLogThresholds(t *testing.T) {
	if got := FavorLogIDsCrossed(0, 99); len(got) != 0 {
		t.Fatalf("below first threshold %v", got)
	}
	if got := FavorLogIDsCrossed(0, 100); !reflect.DeepEqual(got, []int64{80001}) {
		t.Fatalf("cross 100 %v", got)
	}
	if got := FavorLogIDsCrossed(100, 300); !reflect.DeepEqual(got, []int64{80006, 80002}) {
		t.Fatalf("cross 200,300 %v", got)
	}
	if got := FavorLogIDsCrossed(0, 2000); len(got) != 9 || got[0] != 80001 || got[8] != 80005 {
		t.Fatalf("cross all %v", got)
	}
	if got := DialogueLogIDsReached(0, 1); !reflect.DeepEqual(got, []int64{70001}) {
		t.Fatalf("dialogue 1 %v", got)
	}
	if got := DialogueLogIDsReached(9, 30); !reflect.DeepEqual(got, []int64{70002, 70003}) {
		t.Fatalf("dialogue 10,30 %v", got)
	}
	if got := DialogueLogIDsReached(0, 0); len(got) != 0 {
		t.Fatalf("dialogue zero %v", got)
	}
}

func TestHeroLogColorAndStarIDs(t *testing.T) {
	if id, ok := ColorLogID(2); !ok || id != 20001 {
		t.Fatalf("color 2 %d %v", id, ok)
	}
	if id, ok := ColorLogID(14); !ok || id != 20013 {
		t.Fatalf("color 14 %d %v", id, ok)
	}
	if _, ok := ColorLogID(1); ok {
		t.Fatal("color 1 has no promotion entry")
	}
	if _, ok := ColorLogID(15); ok {
		t.Fatal("color 15 has no promotion entry")
	}
	if id, ok := StarLogID(2); !ok || id != 40001 {
		t.Fatalf("star 2 %d %v", id, ok)
	}
	if id, ok := StarLogID(10); !ok || id != 40009 {
		t.Fatalf("star 10 %d %v", id, ok)
	}
	if _, ok := StarLogID(1); ok {
		t.Fatal("star 1 has no star-up entry")
	}
	if _, ok := StarLogID(11); ok {
		t.Fatal("star 11 has no star-up entry")
	}
}
