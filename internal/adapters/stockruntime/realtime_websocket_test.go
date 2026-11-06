package stockruntime

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	app "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/limits"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

type webSocketTestAuthority struct {
	actors map[string]identity.ActorContext
}

func (a webSocketTestAuthority) ResolveGameplayBearer(_ context.Context, token string, _ time.Time) (identity.ActorContext, error) {
	actor, ok := a.actors[token]
	if !ok {
		return identity.ActorContext{}, errors.New("unknown test bearer")
	}
	return actor, nil
}

func (webSocketTestAuthority) ValidateActor(context.Context, identity.ActorContext, time.Time) error {
	return nil
}

func webSocketTestActor(t *testing.T, suffix string, player int64) identity.ActorContext {
	t.Helper()
	account, err := ids.ParseUUID("11111111-1111-4111-8111-11111111111" + suffix)
	if err != nil {
		t.Fatal(err)
	}
	session, err := ids.ParseUUID("22222222-2222-4222-8222-22222222222" + suffix)
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := ids.ParseUUID("33333333-3333-4333-8333-33333333333" + suffix)
	if err != nil {
		t.Fatal(err)
	}
	accountID, _ := identity.AccountIDFrom(account)
	sessionID, _ := identity.SessionIDFrom(session)
	context, _ := identity.ContextIDFrom(contextID)
	return identity.ActorContext{AccountID: accountID, AccountUID: identity.AccountUID("2000000" + suffix), SessionID: sessionID,
		ContextID: context, LogicalServerID: 1, PlayerID: identity.PlayerID(player), ContextGeneration: 3, SessionLivenessVersion: 4, ContextLivenessVersion: 5}
}

// webSocketChatFanout is a minimal session dispatcher: it echoes one validated
// chat frame to every world session in the room and pushes a direct notice to
// the sender, so both transports exercise the production publisher path.
type webSocketChatFanout struct {
	registry  *ConnectionRegistry
	publisher RealtimePublisher
}

func (d webSocketChatFanout) HandleSessionClientFrame(ctx context.Context, sender SessionHandle, admitted app.Admission, frame wireRT.Frame) ([]wireRT.Frame, error) {
	if frame.MID != mids.MIDSendChatMessage {
		return nil, ErrUnsupportedRealtimeMID
	}
	ingress, err := wireRT.ParseChannelChatIngress(frame.Params)
	if err != nil {
		return nil, err
	}
	handles, ok := d.registry.ByRoomRoleBounded(admitted.Domain.RoomID, admitted.Domain.Role, 16)
	if !ok {
		return nil, ErrInvalidRealtimeSession
	}
	chat := &amf3.Object{Properties: []amf3.Property{
		{Name: "player_id", Value: float64(admitted.Domain.Actor.PlayerID)},
		{Name: "player_name", Value: "tester"},
		{Name: "message", Value: ingress.Request.Message},
		{Name: "player_type", Value: float64(0)},
		{Name: "type", Value: float64(0)},
		{Name: "avatar_id", Value: float64(0)},
		{Name: "avatar_frame_id", Value: float64(0)},
		{Name: "lev", Value: float64(1)},
		{Name: "np_info", Value: `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":1}`},
	}}
	for _, target := range handles {
		if err := d.publisher.PublishDirect(ctx, target, mids.MIDChatMessage, chat); err != nil {
			return nil, err
		}
	}
	push := &amf3.Object{Properties: []amf3.Property{{Name: "friend_id", Value: int64(7)}, {Name: "message", Value: "notice"}}}
	if err := d.publisher.PublishDirect(ctx, sender, mids.MIDChatFromPlayer, push); err != nil {
		return nil, err
	}
	return nil, nil
}

func newWebSocketTestServer(t *testing.T) RealtimeServer {
	t.Helper()
	actors := map[string]identity.ActorContext{
		"alpha": webSocketTestActor(t, "1", 100001),
		"beta":  webSocketTestActor(t, "2", 100002),
	}
	registry := NewConnectionRegistry()
	events, err := wireRT.NewEventRegistry([]wireRT.DirectRegistration{
		{MID: mids.MIDChatMessage, Roles: []wireRT.Role{wireRT.World, wireRT.Guild, wireRT.Service}, Validate: wireRT.ValidateChannelChat},
		{MID: mids.MIDChatFromPlayer, Roles: []wireRT.Role{wireRT.World}, Validate: func(value any) error {
			if _, ok := value.(*amf3.Object); !ok {
				return wireRT.ErrInvalidS2CPayload
			}
			return nil
		}},
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	dispatcher := webSocketChatFanout{registry: registry, publisher: RealtimePublisher{Registry: events, Limits: limits.Default()}}
	return RealtimeServer{
		Auth:   app.Service{Authority: webSocketTestAuthority{actors: actors}, Endpoints: rtEndpoint{}},
		Limits: limits.Default(), Policy: DefaultRealtimePolicy(), Registry: registry, SessionDispatcher: dispatcher,
	}
}

func chatRequest(t *testing.T, message string) wireRT.Frame {
	t.Helper()
	return wireRT.Frame{MID: mids.MIDSendChatMessage, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "message", Value: message}, {Name: "channel", Value: float64(0)}, {Name: "type", Value: float64(0)},
	}}}
}

type webSocketTestClient struct {
	conn   net.Conn
	reader *bufio.Reader
	path   string
}

func dialTestWebSocket(t *testing.T, rawURL string) *webSocketTestClient {
	t.Helper()
	parsed, err := url.Parse(rawURL)
	if err != nil {
		t.Fatal(err)
	}
	conn, err := net.Dial("tcp", parsed.Host)
	if err != nil {
		t.Fatal(err)
	}
	key := base64.StdEncoding.EncodeToString([]byte("0123456789abcdef"))
	request := fmt.Sprintf("GET %s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n", parsed.RequestURI(), parsed.Host, key)
	if _, err := conn.Write([]byte(request)); err != nil {
		t.Fatal(err)
	}
	reader := bufio.NewReader(conn)
	status, err := reader.ReadString('\n')
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(status, " 101 ") {
		t.Fatalf("upgrade status %q", status)
	}
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			t.Fatal(err)
		}
		if line == "\r\n" {
			break
		}
	}
	return &webSocketTestClient{conn: conn, reader: reader, path: parsed.RequestURI()}
}

func (c *webSocketTestClient) writeFrame(opcode byte, payload []byte) error {
	header := []byte{0x80 | opcode}
	mask := [4]byte{1, 2, 3, 4}
	switch {
	case len(payload) < 126:
		header = append(header, byte(len(payload))|0x80)
	case len(payload) <= 0xffff:
		header = append(header, 126|0x80, byte(len(payload)>>8), byte(len(payload)))
	default:
		header = append(header, 127|0x80)
		size := make([]byte, 8)
		binary.BigEndian.PutUint64(size, uint64(len(payload)))
		header = append(header, size...)
	}
	header = append(header, mask[:]...)
	for index, value := range payload {
		header = append(header, value^mask[index%4])
	}
	_ = c.conn.SetWriteDeadline(time.Now().Add(2 * time.Second))
	_, err := c.conn.Write(header)
	return err
}

func (c *webSocketTestClient) sendFrame(t *testing.T, frame wireRT.Frame) {
	t.Helper()
	data, err := wireRT.EncodeJSONFrame(frame, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	if err := c.writeFrame(webSocketOpcodeText, data); err != nil {
		t.Fatal(err)
	}
}

func (c *webSocketTestClient) readMessage(ctx context.Context) (byte, []byte, error) {
	if deadline, ok := ctx.Deadline(); ok {
		_ = c.conn.SetReadDeadline(deadline)
	}
	var messageOpcode byte
	var message []byte
	for {
		head := make([]byte, 2)
		if _, err := io.ReadFull(c.reader, head); err != nil {
			return 0, nil, err
		}
		final := head[0]&0x80 != 0
		opcode := head[0] & 0x0f
		if head[1]&0x80 != 0 {
			return 0, nil, ErrWebSocketProtocol
		}
		length := int64(head[1] & 0x7f)
		if length == 126 {
			raw := make([]byte, 2)
			if _, err := io.ReadFull(c.reader, raw); err != nil {
				return 0, nil, err
			}
			length = int64(binary.BigEndian.Uint16(raw))
		} else if length == 127 {
			raw := make([]byte, 8)
			if _, err := io.ReadFull(c.reader, raw); err != nil {
				return 0, nil, err
			}
			length = int64(binary.BigEndian.Uint64(raw))
		}
		payload := make([]byte, length)
		if _, err := io.ReadFull(c.reader, payload); err != nil {
			return 0, nil, err
		}
		switch opcode {
		case webSocketOpcodePing:
			_ = c.writeFrame(webSocketOpcodePong, payload)
		case webSocketOpcodePong:
		case webSocketOpcodeClose:
			return 0, nil, ErrWebSocketClosed
		case webSocketOpcodeText, webSocketOpcodeBinary:
			messageOpcode = opcode
			message = payload
		case webSocketOpcodeContinuation:
			message = append(message, payload...)
		default:
			return 0, nil, ErrWebSocketProtocol
		}
		if final && messageOpcode != 0 {
			return messageOpcode, message, nil
		}
	}
}

func (c *webSocketTestClient) receiveFrame(t *testing.T) wireRT.Frame {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	opcode, data, err := c.readMessage(ctx)
	if err != nil {
		t.Fatalf("websocket read: %v", err)
	}
	if opcode != webSocketOpcodeText {
		t.Fatalf("websocket opcode %d", opcode)
	}
	frame, err := wireRT.DecodeJSONFrame(data, limits.Default())
	if err != nil {
		t.Fatalf("decode websocket frame %s: %v", data, err)
	}
	return frame
}

func (c *webSocketTestClient) close() { _ = c.conn.Close() }

func webSocketLogin(token string) wireRT.Frame {
	return wireRT.Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "token", Value: token}, {Name: "region", Value: int32(1)}, {Name: "room_id", Value: int32(1)},
	}}}
}

type tcpTestClient struct {
	conn    net.Conn
	decoder *wireRT.StreamDecoder
}

func newTCPTestClient(t *testing.T, ctx context.Context, server RealtimeServer) *tcpTestClient {
	t.Helper()
	serverSide, clientSide := net.Pipe()
	go func() { _ = server.ServeConn(ctx, serverSide) }()
	decoder, err := wireRT.NewStreamDecoder(limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	return &tcpTestClient{conn: clientSide, decoder: decoder}
}

func (c *tcpTestClient) send(t *testing.T, frame wireRT.Frame) {
	t.Helper()
	data, err := wireRT.EncodeFrame(frame)
	if err != nil {
		t.Fatal(err)
	}
	_ = c.conn.SetWriteDeadline(time.Now().Add(2 * time.Second))
	if _, err := c.conn.Write(data); err != nil {
		t.Fatal(err)
	}
}

func (c *tcpTestClient) receive(t *testing.T) wireRT.Frame {
	t.Helper()
	buffer := make([]byte, 8192)
	for {
		_ = c.conn.SetReadDeadline(time.Now().Add(2 * time.Second))
		n, err := c.conn.Read(buffer)
		if err != nil {
			t.Fatalf("tcp read: %v", err)
		}
		frames, err := c.decoder.Feed(buffer[:n])
		if err != nil {
			t.Fatal(err)
		}
		if len(frames) == 0 {
			continue
		}
		return frames[0]
	}
}

func TestWebSocketChatAndPushReachWebSocketAndTCP(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	server := newWebSocketTestServer(t)
	httpServer := httptest.NewServer(server.WebSocketHandler(ctx))
	defer httpServer.Close()
	url := "ws" + strings.TrimPrefix(httpServer.URL, "http") + WebSocketPath

	alpha := dialTestWebSocket(t, url)
	defer alpha.close()
	alpha.sendFrame(t, webSocketLogin("alpha"))
	if ack := alpha.receiveFrame(t); ack.MID != mids.MIDChatRoomEntered {
		t.Fatalf("alpha ack mid=%d", ack.MID)
	}

	beta := newTCPTestClient(t, ctx, server)
	defer beta.conn.Close()
	beta.send(t, webSocketLogin("beta"))
	if ack := beta.receive(t); ack.MID != mids.MIDChatRoomEntered {
		t.Fatalf("beta ack mid=%d", ack.MID)
	}

	alpha.sendFrame(t, chatRequest(t, "hello from websocket"))
	chat := beta.receive(t)
	if chat.MID != mids.MIDChatMessage {
		t.Fatalf("tcp chat mid=%d", chat.MID)
	}
	if message, ok := chat.Params.(*amf3.Object).Map()["message"].(string); !ok || message != "hello from websocket" {
		t.Fatalf("tcp chat message=%v", chat.Params)
	}
	if chat := alpha.receiveFrame(t); chat.MID != mids.MIDChatMessage {
		t.Fatalf("ws chat mid=%d", chat.MID)
	}
	if push := alpha.receiveFrame(t); push.MID != mids.MIDChatFromPlayer {
		t.Fatalf("ws push mid=%d", push.MID)
	}
}

func TestWebSocketTCPChatReachesReconnectedWebSocket(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	server := newWebSocketTestServer(t)
	httpServer := httptest.NewServer(server.WebSocketHandler(ctx))
	defer httpServer.Close()
	url := "ws" + strings.TrimPrefix(httpServer.URL, "http") + WebSocketPath

	first := dialTestWebSocket(t, url)
	first.sendFrame(t, webSocketLogin("alpha"))
	if ack := first.receiveFrame(t); ack.MID != mids.MIDChatRoomEntered {
		t.Fatalf("first ack mid=%d", ack.MID)
	}
	first.close()

	reconnected := dialTestWebSocket(t, url)
	defer reconnected.close()
	reconnected.sendFrame(t, webSocketLogin("alpha"))
	if ack := reconnected.receiveFrame(t); ack.MID != mids.MIDChatRoomEntered {
		t.Fatalf("reconnect ack mid=%d", ack.MID)
	}

	beta := newTCPTestClient(t, ctx, server)
	defer beta.conn.Close()
	beta.send(t, webSocketLogin("beta"))
	if ack := beta.receive(t); ack.MID != mids.MIDChatRoomEntered {
		t.Fatalf("beta ack mid=%d", ack.MID)
	}
	beta.send(t, chatRequest(t, "hello from tcp"))
	if chat := reconnected.receiveFrame(t); chat.MID != mids.MIDChatMessage {
		t.Fatalf("reconnected ws chat mid=%d", chat.MID)
	}
}

func TestWebSocketBadJSONAndUnknownMIDCloseLikeTCP(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	server := newWebSocketTestServer(t)
	httpServer := httptest.NewServer(server.WebSocketHandler(ctx))
	defer httpServer.Close()
	url := "ws" + strings.TrimPrefix(httpServer.URL, "http") + WebSocketPath

	cases := []struct {
		name string
		send func(*webSocketTestClient)
	}{
		{name: "bad json", send: func(client *webSocketTestClient) {
			_ = client.writeFrame(webSocketOpcodeText, []byte(`{"mid":32782,"data":`))
		}},
		{name: "unknown mid", send: func(client *webSocketTestClient) {
			client.sendFrame(t, wireRT.Frame{MID: 12345, Params: &amf3.Object{}})
		}},
	}
	for _, testCase := range cases {
		t.Run(testCase.name, func(t *testing.T) {
			client := dialTestWebSocket(t, url)
			defer client.close()
			client.sendFrame(t, webSocketLogin("alpha"))
			if ack := client.receiveFrame(t); ack.MID != mids.MIDChatRoomEntered {
				t.Fatalf("ack mid=%d", ack.MID)
			}
			testCase.send(client)
			readCtx, stop := context.WithTimeout(context.Background(), 2*time.Second)
			defer stop()
			if _, _, err := client.readMessage(readCtx); err == nil {
				t.Fatal("server did not close the session")
			}
		})
	}
}

func TestWebSocketBinaryFrameIsRejected(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	server := newWebSocketTestServer(t)
	httpServer := httptest.NewServer(server.WebSocketHandler(ctx))
	defer httpServer.Close()
	url := "ws" + strings.TrimPrefix(httpServer.URL, "http") + WebSocketPath
	client := dialTestWebSocket(t, url)
	defer client.close()
	if err := client.writeFrame(webSocketOpcodeBinary, []byte{1, 2, 3}); err != nil {
		t.Fatal(err)
	}
	readCtx, stop := context.WithTimeout(context.Background(), 2*time.Second)
	defer stop()
	if _, _, err := client.readMessage(readCtx); err == nil {
		t.Fatal("binary frame was not rejected")
	}
}

func TestJSONAndTCPFramesDecodeToSameValues(t *testing.T) {
	object := &amf3.Object{Properties: []amf3.Property{
		{Name: "message", Value: "same"}, {Name: "channel", Value: float64(0)}, {Name: "type", Value: float64(0)},
		{Name: "none", Value: nil}, {Name: "list", Value: []any{float64(1), "x"}},
	}}
	tcpBytes, err := wireRT.EncodeFrame(wireRT.Frame{MID: mids.MIDSendChatMessage, Params: object})
	if err != nil {
		t.Fatal(err)
	}
	decoder, _ := wireRT.NewStreamDecoder(limits.Default())
	tcpFrames, err := decoder.Feed(tcpBytes)
	if err != nil {
		t.Fatal(err)
	}
	jsonBytes, err := wireRT.EncodeJSONFrame(tcpFrames[0], limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	jsonFrame, err := wireRT.DecodeJSONFrame(jsonBytes, limits.Default())
	if err != nil {
		t.Fatal(err)
	}
	if jsonFrame.MID != tcpFrames[0].MID {
		t.Fatalf("mid %d != %d", jsonFrame.MID, tcpFrames[0].MID)
	}
	tcpMap := tcpFrames[0].Params.(*amf3.Object).Map()
	jsonMap := jsonFrame.Params.(*amf3.Object).Map()
	if len(tcpMap) != len(jsonMap) || jsonMap["message"] != tcpMap["message"] {
		t.Fatalf("tcp=%#v json=%#v", tcpMap, jsonMap)
	}
	list, ok := jsonMap["list"].([]any)
	number, numeric := list[0].(int32)
	if !ok || len(list) != 2 || !numeric || number != 1 || list[1] != "x" {
		t.Fatalf("list=%#v", jsonMap["list"])
	}
	if _, ok := jsonMap["channel"].(int32); !ok {
		t.Fatalf("channel type %T", jsonMap["channel"])
	}
}
