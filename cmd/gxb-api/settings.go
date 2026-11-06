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
