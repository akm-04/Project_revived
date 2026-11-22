// Package eventscontent embeds the shipped default event cycle (I11A_EVENTS_V1
// ruling 8). The body is data: domain/events parses and validates it.
package eventscontent

import _ "embed"

//go:embed default_cycle.json
var defaultCycleJSON []byte

// DefaultCycle returns the shipped body. The caller parses it once at startup.
func DefaultCycle() []byte {
	return append([]byte(nil), defaultCycleJSON...)
}
