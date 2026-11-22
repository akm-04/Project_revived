package stockruntime

import (
	"os"
	"time"
)

const (
	eventWaitTimeoutEnvironment = "GXB_TEST_WAIT_TIMEOUT"
	defaultEventWaitTimeout     = 10 * time.Second
)

// eventWaitTimeout bounds waits for an event a test requires; a loaded host may deliver it late.
var eventWaitTimeout = readEventWaitTimeout()

func readEventWaitTimeout() time.Duration {
	value := os.Getenv(eventWaitTimeoutEnvironment)
	if value == "" {
		return defaultEventWaitTimeout
	}
	parsed, err := time.ParseDuration(value)
	if err != nil || parsed <= 0 {
		return defaultEventWaitTimeout
	}
	return parsed
}
