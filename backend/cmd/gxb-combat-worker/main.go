// Command gxb-combat-worker resolves one frozen combat snapshot from stdin.
// It applies the launcher's resource limits to itself before reading input.
package main

import (
	"flag"
	"fmt"
	"os"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
)

func main() {
	memory := flag.Uint64("max-address-space", 0, "RLIMIT_AS bytes")
	cpu := flag.Uint64("max-cpu-seconds", 0, "RLIMIT_CPU seconds")
	files := flag.Uint64("max-open-files", 0, "RLIMIT_NOFILE")
	flag.Parse()
	if err := applyLimits(*memory, *cpu, *files); err != nil {
		fmt.Fprintln(os.Stderr, "combat worker:", err)
		os.Exit(3)
	}
	if err := combatresolver.Serve(os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "combat worker:", err)
		os.Exit(4)
	}
}
