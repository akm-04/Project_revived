package occult

import (
	"testing"
	"time"
)

func TestI912ChapterScoreFactUsesBestAndSkipsMissingOrZero(t *testing.T) {
	at := time.Unix(1000, 0).UTC()
	revision := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	scores := Scores{"1": 7, "3": 120, "4": 0}
	fact, found, e := BuildChapterScoreFact(1, 3, scores, revision, at)
	if e != nil || !found || fact.Value != 120 || fact.ChapterID != 3 || fact.SourceVersion != 1 || fact.Revision != revision || !fact.ObservedAt.Equal(at) {
		t.Fatal(fact, found, e)
	}
	if e = fact.Validate(at); e != nil {
		t.Fatal(e)
	}
	if _, found, e = BuildChapterScoreFact(1, 2, scores, revision, at); e != nil || found {
		t.Fatal("chapter without a score must yield no fact", found, e)
	}
	if _, found, e = BuildChapterScoreFact(1, 4, scores, revision, at); e != nil || found {
		t.Fatal("zero best must yield no fact", found, e)
	}
	if _, _, e = BuildChapterScoreFact(1, 3, Scores{"3": -1}, revision, at); e == nil {
		t.Fatal("negative score accepted")
	}
	if _, _, e = BuildChapterScoreFact(1, 3, Scores{"chapter": 1}, revision, at); e == nil {
		t.Fatal("non-numeric chapter accepted")
	}
	if e = fact.Validate(at.Add(time.Second)); e == nil {
		t.Fatal("wrong observation instant accepted")
	}
}
