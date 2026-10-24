package limits

import (
	"errors"
	"time"
)

const (
	NativeFramePayloadMax     = 65536
	StockOrdinaryHTTPTimeout  = 20 * time.Second
	StockMultipartHTTPTimeout = 30 * time.Second
	StockTCPLoginTimeout      = 10 * time.Second
	StockTCPReconnectDelay    = 5 * time.Second
	StockHeartbeatInterval    = 600 * time.Second
)

// Config values are V2 engineering safety policy unless named Stock*/Native* above.
// They are intentionally not represented as recovered original-server constants.
type Config struct {
	OrdinaryBodyBytes     int64
	MultipartBodyBytes    int64
	UploadBodyBytes       int64
	UploadFileBytes       int64
	MultipartParts        int
	FieldBytes            int64
	CompressedBytes       int64
	InflatedBytes         int64
	MaxInflateRatio       int64
	JSONDepth             int
	JSONNodes             int
	AMFDepth              int
	AMFNodes              int
	AMFStringBytes        int
	AMFProperties         int
	AMFArrayElements      int
	AMFReferences         int
	AMFOutputBytes        int
	RealtimeBufferedBytes int
	WriterFrames          int
	WriterBytes           int
}

func Default() Config {
	return Config{
		OrdinaryBodyBytes:     1 << 20,
		MultipartBodyBytes:    2 << 20,
		UploadBodyBytes:       10 << 20,
		UploadFileBytes:       8 << 20,
		MultipartParts:        64,
		FieldBytes:            128 << 10,
		CompressedBytes:       1 << 20,
		InflatedBytes:         4 << 20,
		MaxInflateRatio:       128,
		JSONDepth:             64,
		JSONNodes:             100000,
		AMFDepth:              64,
		AMFNodes:              100000,
		AMFStringBytes:        4 << 20,
		AMFProperties:         65536,
		AMFArrayElements:      65536,
		AMFReferences:         65536,
		AMFOutputBytes:        NativeFramePayloadMax,
		RealtimeBufferedBytes: 4 * (NativeFramePayloadMax + 10),
		WriterFrames:          256,
		WriterBytes:           2 << 20,
	}
}

func (c Config) Validate() error {
	if c.OrdinaryBodyBytes <= 0 || c.MultipartBodyBytes <= 0 || c.UploadBodyBytes <= 0 || c.UploadFileBytes <= 0 {
		return errors.New("body/file limits must be positive")
	}
	if c.UploadFileBytes > c.UploadBodyBytes {
		return errors.New("upload file limit exceeds total upload body limit")
	}
	if c.MultipartParts <= 0 || c.FieldBytes <= 0 || c.CompressedBytes <= 0 || c.InflatedBytes <= 0 || c.MaxInflateRatio <= 0 {
		return errors.New("multipart/inflate limits must be positive")
	}
	if c.JSONDepth <= 0 || c.JSONNodes <= 0 || c.AMFDepth <= 0 || c.AMFNodes <= 0 || c.AMFStringBytes <= 0 || c.AMFProperties <= 0 || c.AMFArrayElements <= 0 || c.AMFReferences <= 0 || c.AMFOutputBytes <= 0 {
		return errors.New("structured protocol budgets must be positive")
	}
	if c.AMFOutputBytes > NativeFramePayloadMax {
		return errors.New("AMF output budget exceeds native frame payload maximum")
	}
	if c.RealtimeBufferedBytes < NativeFramePayloadMax+10 {
		return errors.New("realtime buffer must fit one maximum native frame")
	}
	if c.WriterFrames <= 0 || c.WriterBytes < NativeFramePayloadMax+10 {
		return errors.New("writer queue budget too small")
	}
	return nil
}
