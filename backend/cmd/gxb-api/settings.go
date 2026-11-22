package main

import (
	"log"
	"os"
	"strconv"
	"time"
)

// envPositiveInt reads an optional positive integer setting. Absence keeps the
// caller's default; a present but invalid value is fatal so a typo cannot
// silently run with a different capacity than the operator chose.
func envPositiveInt(name string, fallback int) int {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback
	}
	value, err := strconv.Atoi(raw)
	if err != nil || value <= 0 {
		log.Fatalf("%s must be a positive integer, got %q", name, raw)
	}
	return value
}

// envBool reads an optional boolean setting. Absence is false; a present but
// invalid value is fatal so a typo cannot silently keep a policy gate.
func envBool(name string) bool {
	raw := os.Getenv(name)
	if raw == "" {
		return false
	}
	value, err := strconv.ParseBool(raw)
	if err != nil {
		log.Fatalf("%s must be a boolean, got %q", name, raw)
	}
	return value
}

// handlerConcurrency reads a route-level concurrency cap and clamps it to at
// most half the gameplay pool, so a route outside edge admission can never hold
// more than its share of connections.
func handlerConcurrency(name string, fallback, poolConnections int) int {
	return min(envPositiveInt(name, fallback), max(poolConnections/2, 1))
}

func envPositiveDuration(name string, fallback time.Duration) time.Duration {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback
	}
	value, err := time.ParseDuration(raw)
	if err != nil || value <= 0 {
		log.Fatalf("%s must be a positive duration, got %q", name, raw)
	}
	return value
}

// envDurationWithin reads an optional bounded duration setting. Absence keeps
// the fallback; a present but out-of-range value is fatal at startup.
func envDurationWithin(name string, fallback, minimum, maximum time.Duration) time.Duration {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback
	}
	value, err := time.ParseDuration(raw)
	if err != nil || value < minimum || value > maximum {
		log.Fatalf("%s must be a duration between %s and %s, got %q", name, minimum, maximum, raw)
	}
	return value
}
