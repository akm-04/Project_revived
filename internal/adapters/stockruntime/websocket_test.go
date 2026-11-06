package stockruntime

import (
	"bufio"
	"context"
	"encoding/binary"
	"errors"
	"io"
	"net"
	"testing"
	"time"
)

func writeTestClientFrame(t *testing.T, conn net.Conn, final bool, opcode byte, payload []byte, masked bool) {
	t.Helper()
	first := opcode
	if final {
		first |= 0x80
	}
	header := []byte{first}
	maskBit := byte(0)
	if masked {
		maskBit = 0x80
	}
	switch {
	case len(payload) < 126:
		header = append(header, byte(len(payload))|maskBit)
	case len(payload) <= 0xffff:
		header = append(header, 126|maskBit, byte(len(payload)>>8), byte(len(payload)))
	default:
		header = append(header, 127|maskBit)
		size := make([]byte, 8)
		binary.BigEndian.PutUint64(size, uint64(len(payload)))
		header = append(header, size...)
	}
	if masked {
		mask := []byte{1, 2, 3, 4}
		header = append(header, mask...)
		for index, value := range payload {
			header = append(header, value^mask[index%4])
		}
	} else {
		header = append(header, payload...)
	}
	if _, err := conn.Write(header); err != nil {
		t.Fatal(err)
	}
}

func readTestServerFrame(t *testing.T, reader *bufio.Reader) (byte, []byte) {
	t.Helper()
	head := make([]byte, 2)
	if _, err := io.ReadFull(reader, head); err != nil {
		t.Fatal(err)
	}
	if head[1]&0x80 != 0 {
		t.Fatal("server frame is masked")
	}
	length := int64(head[1] & 0x7f)
	if length == 126 {
		raw := make([]byte, 2)
		if _, err := io.ReadFull(reader, raw); err != nil {
			t.Fatal(err)
		}
		length = int64(binary.BigEndian.Uint16(raw))
	}
	payload := make([]byte, length)
	if _, err := io.ReadFull(reader, payload); err != nil {
		t.Fatal(err)
	}
	return head[0] & 0x0f, payload
}

func newWebSocketPipe(t *testing.T) (*webSocketConn, net.Conn, *bufio.Reader) {
	t.Helper()
	server, client := net.Pipe()
	return &webSocketConn{transport: server, reader: bufio.NewReader(server), maxBytes: 1024}, client, bufio.NewReader(client)
}

func TestWebSocketReadMessageFragmentsAndControlFrames(t *testing.T) {
	socket, client, clientReader := newWebSocketPipe(t)
	defer client.Close()
	go func() {
		writeTestClientFrame(t, client, false, webSocketOpcodeText, []byte("hel"), true)
		writeTestClientFrame(t, client, true, webSocketOpcodeContinuation, []byte("lo"), true)
	}()
	opcode, payload, err := socket.ReadMessage(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if opcode != webSocketOpcodeText || string(payload) != "hello" {
		t.Fatalf("opcode=%d payload=%q", opcode, payload)
	}

	go func() {
		writeTestClientFrame(t, client, true, webSocketOpcodePing, []byte("p"), true)
	}()
	go func() {
		pongOpcode, pongPayload := readTestServerFrame(t, clientReader)
		if pongOpcode != webSocketOpcodePong || string(pongPayload) != "p" {
			t.Errorf("pong opcode=%d payload=%q", pongOpcode, pongPayload)
		}
		writeTestClientFrame(t, client, true, webSocketOpcodeText, []byte("after"), true)
	}()
	opcode, payload, err = socket.ReadMessage(context.Background())
	if err != nil || opcode != webSocketOpcodeText || string(payload) != "after" {
		t.Fatalf("opcode=%d payload=%q err=%v", opcode, payload, err)
	}
}

func TestWebSocketRejectsUnmaskedAndOversizedFrames(t *testing.T) {
	socket, client, _ := newWebSocketPipe(t)
	defer client.Close()
	go func() { writeTestClientFrame(t, client, true, webSocketOpcodeText, []byte("x"), false) }()
	if _, _, err := socket.ReadMessage(context.Background()); !errors.Is(err, ErrWebSocketProtocol) {
		t.Fatalf("unmasked err=%v", err)
	}

	socket, client, _ = newWebSocketPipe(t)
	defer client.Close()
	go func() {
		header := []byte{0x81, 0x80 | 126, 0x04, 0x01, 1, 1, 1, 1}
		_, _ = client.Write(header)
	}()
	if _, _, err := socket.ReadMessage(context.Background()); !errors.Is(err, ErrWebSocketProtocol) {
		t.Fatalf("oversized err=%v", err)
	}
}

func TestWebSocketCloseFrameCloses(t *testing.T) {
	socket, client, clientReader := newWebSocketPipe(t)
	defer client.Close()
	writeDone := make(chan struct{})
	go func() {
		defer close(writeDone)
		writeTestClientFrame(t, client, true, webSocketOpcodeClose, []byte{0x03, 0xe8}, true)
		opcode, _ := readTestServerFrame(t, clientReader)
		if opcode != webSocketOpcodeClose {
			t.Errorf("close echo opcode=%d", opcode)
		}
	}()
	if _, _, err := socket.ReadMessage(context.Background()); !errors.Is(err, ErrWebSocketClosed) {
		t.Fatalf("close err=%v", err)
	}
	select {
	case <-writeDone:
	case <-time.After(time.Second):
		t.Fatal("close echo not received")
	}
}
