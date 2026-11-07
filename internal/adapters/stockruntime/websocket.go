package stockruntime

import (
	"bufio"
	"context"
	"crypto/sha1"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

const webSocketAcceptGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

const (
	webSocketOpcodeContinuation = 0x0
	webSocketOpcodeText         = 0x1
	webSocketOpcodeBinary       = 0x2
	webSocketOpcodeClose        = 0x8
	webSocketOpcodePing         = 0x9
	webSocketOpcodePong         = 0xa
)

var (
	ErrWebSocketProtocol = errors.New("malformed websocket frame")
	ErrWebSocketClosed   = errors.New("websocket closed")
)

// webSocketConn is the minimal RFC 6455 server connection the realtime
// transport needs: one text/binary message per read, unmasked server writes and
// ping/close control handling. It deliberately offers no extensions.
type webSocketConn struct {
	transport net.Conn
	reader    *bufio.Reader
	writeLock sync.Mutex
	closed    bool
	maxBytes  int64
}

func headerHasToken(header http.Header, name, token string) bool {
	for _, value := range header.Values(name) {
		for _, part := range strings.Split(value, ",") {
			if strings.EqualFold(strings.TrimSpace(part), token) {
				return true
			}
		}
	}
	return false
}

func upgradeWebSocket(w http.ResponseWriter, r *http.Request, maxBytes int64) (*webSocketConn, error) {
	if r.Method != http.MethodGet || !headerHasToken(r.Header, "Connection", "upgrade") ||
		!strings.EqualFold(r.Header.Get("Upgrade"), "websocket") {
		http.Error(w, "websocket upgrade required", http.StatusBadRequest)
		return nil, ErrWebSocketProtocol
	}
	if r.Header.Get("Sec-WebSocket-Version") != "13" {
		w.Header().Set("Sec-WebSocket-Version", "13")
		http.Error(w, "unsupported websocket version", http.StatusUpgradeRequired)
		return nil, ErrWebSocketProtocol
	}
	key := r.Header.Get("Sec-WebSocket-Key")
	if key == "" {
		http.Error(w, "missing websocket key", http.StatusBadRequest)
		return nil, ErrWebSocketProtocol
	}
	hijacker, ok := w.(http.Hijacker)
	if !ok {
		http.Error(w, "websocket unsupported", http.StatusInternalServerError)
		return nil, errors.New("http hijacking unsupported")
	}
	conn, buffered, err := hijacker.Hijack()
	if err != nil {
		return nil, err
	}
	digest := sha1.Sum([]byte(key + webSocketAcceptGUID))
	accept := base64.StdEncoding.EncodeToString(digest[:])
	response := "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " + accept + "\r\n\r\n"
	if _, err := buffered.WriteString(response); err != nil {
		_ = conn.Close()
		return nil, err
	}
	if err := buffered.Flush(); err != nil {
		_ = conn.Close()
		return nil, err
	}
	return &webSocketConn{transport: conn, reader: buffered.Reader, maxBytes: maxBytes}, nil
}

func readWebSocketFrame(reader *bufio.Reader, maxBytes int64) (bool, byte, []byte, error) {
	head := make([]byte, 2)
	if _, err := io.ReadFull(reader, head); err != nil {
		return false, 0, nil, err
	}
	final := head[0]&0x80 != 0
	if head[0]&0x70 != 0 {
		return false, 0, nil, ErrWebSocketProtocol
	}
	opcode := head[0] & 0x0f
	masked := head[1]&0x80 != 0
	if !masked {
		return false, 0, nil, ErrWebSocketProtocol
	}
	length := int64(head[1] & 0x7f)
	switch length {
	case 126:
		raw := make([]byte, 2)
		if _, err := io.ReadFull(reader, raw); err != nil {
			return false, 0, nil, err
		}
		length = int64(binary.BigEndian.Uint16(raw))
	case 127:
		raw := make([]byte, 8)
		if _, err := io.ReadFull(reader, raw); err != nil {
			return false, 0, nil, err
		}
		length = int64(binary.BigEndian.Uint64(raw))
		if length < 0 {
			return false, 0, nil, ErrWebSocketProtocol
		}
	}
	if length > maxBytes {
		return false, 0, nil, ErrWebSocketProtocol
	}
	if opcode >= webSocketOpcodeClose && (!final || length > 125) {
		return false, 0, nil, ErrWebSocketProtocol
	}
	mask := make([]byte, 4)
	if _, err := io.ReadFull(reader, mask); err != nil {
		return false, 0, nil, err
	}
	payload := make([]byte, length)
	if _, err := io.ReadFull(reader, payload); err != nil {
		return false, 0, nil, err
	}
	for index := range payload {
		payload[index] ^= mask[index%4]
	}
	return final, opcode, payload, nil
}

func (c *webSocketConn) SetReadDeadline(deadline time.Time) error {
	return c.transport.SetReadDeadline(deadline)
}

// ReadMessage returns one complete text or binary message. Control frames are
// handled here; a close frame returns ErrWebSocketClosed after the echo.
func (c *webSocketConn) ReadMessage(ctx context.Context) (byte, []byte, error) {
	if deadline, ok := ctx.Deadline(); ok {
		_ = c.transport.SetReadDeadline(deadline)
	}
	var messageOpcode byte
	var message []byte
	for {
		final, opcode, payload, err := readWebSocketFrame(c.reader, c.maxBytes)
		if err != nil {
			if errors.Is(err, io.EOF) {
				return 0, nil, ErrWebSocketClosed
			}
			return 0, nil, err
		}
		switch opcode {
		case webSocketOpcodePing:
			_ = c.writeMessage(context.Background(), webSocketOpcodePong, payload)
			continue
		case webSocketOpcodePong:
			continue
		case webSocketOpcodeClose:
			_ = c.writeMessage(context.Background(), webSocketOpcodeClose, nil)
			_ = c.transport.Close()
			return 0, nil, ErrWebSocketClosed
		case webSocketOpcodeText, webSocketOpcodeBinary:
			if messageOpcode != 0 {
				return 0, nil, ErrWebSocketProtocol
			}
			messageOpcode = opcode
			message = payload
		case webSocketOpcodeContinuation:
			if messageOpcode == 0 {
				return 0, nil, ErrWebSocketProtocol
			}
			message = append(message, payload...)
			if int64(len(message)) > c.maxBytes {
				return 0, nil, ErrWebSocketProtocol
			}
		default:
			return 0, nil, ErrWebSocketProtocol
		}
		if final && messageOpcode != 0 {
			return messageOpcode, message, nil
		}
	}
}

func (c *webSocketConn) writeMessage(ctx context.Context, opcode byte, payload []byte) error {
	if deadline, ok := ctx.Deadline(); ok {
		_ = c.transport.SetWriteDeadline(deadline)
	} else {
		_ = c.transport.SetWriteDeadline(time.Time{})
	}
	header := []byte{0x80 | opcode}
	switch {
	case len(payload) < 126:
		header = append(header, byte(len(payload)))
	case len(payload) <= 0xffff:
		header = append(header, 126, byte(len(payload)>>8), byte(len(payload)))
	default:
		header = append(header, 127)
		size := make([]byte, 8)
		binary.BigEndian.PutUint64(size, uint64(len(payload)))
		header = append(header, size...)
	}
	header = append(header, payload...)
	c.writeLock.Lock()
	defer c.writeLock.Unlock()
	if c.closed {
		return ErrWebSocketClosed
	}
	_, err := c.transport.Write(header)
	return err
}

func (c *webSocketConn) WriteText(ctx context.Context, payload []byte) error {
	return c.writeMessage(ctx, webSocketOpcodeText, payload)
}

func (c *webSocketConn) CloseNow() error {
	c.writeLock.Lock()
	c.closed = true
	c.writeLock.Unlock()
	if c.transport == nil {
		return nil
	}
	return c.transport.Close()
}
