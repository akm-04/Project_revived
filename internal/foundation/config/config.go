package config

import (
	"fmt"
	"os"
)

// Config contains process-level bootstrap settings only. Secret values must never be formatted or logged.
type Config struct {
	Environment     string
	LogLevel        string
	PostgresDSN     Secret
	HTTPAddr        string
	RealtimeAddr    string
	ClientLogURL    string
	PublicEngineURL string
}

type Secret string

func (Secret) String() string   { return "[REDACTED]" }
func (Secret) GoString() string { return "[REDACTED]" }

func FromEnv() Config {
	return Config{
		Environment:     envDefault("GXB_ENV", "dev"),
		LogLevel:        envDefault("GXB_LOG_LEVEL", "info"),
		PostgresDSN:     Secret(os.Getenv("GXB_POSTGRES_DSN")),
		HTTPAddr:        envDefault("GXB_HTTP_ADDR", "127.0.0.1:8080"),
		RealtimeAddr:    envDefault("GXB_REALTIME_ADDR", "127.0.0.1:9000"),
		ClientLogURL:    os.Getenv("GXB_CLIENT_LOG_URL"),
		PublicEngineURL: os.Getenv("GXB_PUBLIC_ENGINE_URL"),
	}
}
func envDefault(k, v string) string {
	if x := os.Getenv(k); x != "" {
		return x
	}
	return v
}
func (c Config) String() string {
	return fmt.Sprintf("env=%s log=%s postgres=%s http=%s realtime=%s", c.Environment, c.LogLevel, c.PostgresDSN, c.HTTPAddr, c.RealtimeAddr)
}
