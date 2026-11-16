package adventure

import "strings"

const fantasyGenerationKind = "ADVENTURE_ILLUSION"

// FantasyGeneration is the Combat generation_ref a 2421 START freezes: the
// occurrence's source key, the stable name of the occurrence a late 2422 result
// may credit. Combat owns the attempt; Adventure owns only its settlement.
func FantasyGeneration(occurrence Occurrence) string {
	return fantasyGenerationKind + "/" + occurrence.SourceKey
}

// ParseFantasyGeneration reads a frozen START's occurrence source key.
func ParseFantasyGeneration(reference string) (string, bool) {
	sourceKey, found := strings.CutPrefix(reference, fantasyGenerationKind+"/")
	if !found || strings.TrimSpace(sourceKey) == "" {
		return "", false
	}
	return sourceKey, true
}
