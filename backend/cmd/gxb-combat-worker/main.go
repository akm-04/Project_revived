// Command gxb-combat-worker resolves one frozen combat snapshot from stdin.
// It applies the launcher's resource limits to itself before reading input.
package main

import (
	"flag"
	"fmt"
	"os"
	"syscall"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
)

func main() {
	memory := flag.Uint64("max-address-space", 0, "RLIMIT_AS bytes")
	cpu := flag.Uint64("max-cpu-seconds", 0, "RLIMIT_CPU seconds")
	files := flag.Uint64("max-open-files", 0, "RLIMIT_NOFILE")
	flag.Parse()
	limits := []struct {
		resource int
		value    uint64
	}{{syscall.RLIMIT_AS, *memory}, {syscall.RLIMIT_CPU, *cpu}, {syscall.RLIMIT_NOFILE, *files}, {syscall.RLIMIT_FSIZE, 0}, {syscall.RLIMIT_CORE, 0}}
	for _, limit := range limits {
		if limit.value == 0 && limit.resource != syscall.RLIMIT_FSIZE && limit.resource != syscall.RLIMIT_CORE {
			fmt.Fprintln(os.Stderr, "combat worker: every resource limit is required")
			os.Exit(3)
		}
		if err := syscall.Setrlimit(limit.resource, &syscall.Rlimit{Cur: limit.value, Max: limit.value}); err != nil {
			fmt.Fprintln(os.Stderr, "combat worker: setrlimit:", err)
			os.Exit(3)
		}
	}
	if err := combatresolver.Serve(os.Stdin, os.Stdout); err != nil {
		fmt.Fprintln(os.Stderr, "combat worker:", err)
		os.Exit(4)
	}
}
