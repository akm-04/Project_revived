package stockruntime

import (
	"context"
	"errors"
	"net/http"
	"sync"
	"time"

	"gxb.local/backend/v2/internal/protocol/limits"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
)

// WebSocketPath is the single HTTP path shared by the asset front and the
// realtime service for the JSON realtime transport.
const WebSocketPath = "/realtime/ws"

type webSocketFrameSource struct {
	socket   *webSocketConn
	cfg      limits.Config
	mutex    sync.Mutex
	deadline time.Time
}

func (r *webSocketFrameSource) SetReadDeadline(deadline time.Time) error {
	r.mutex.Lock()
	r.deadline = deadline
	r.mutex.Unlock()
	return nil
}

func (r *webSocketFrameSource) ReadFrames(ctx context.Context) ([]wireRT.Frame, error) {
	r.mutex.Lock()
	deadline := r.deadline
	r.mutex.Unlock()
	if !deadline.IsZero() {
		var cancel context.CancelFunc
		ctx, cancel = context.WithDeadline(ctx, deadline)
		defer cancel()
	}
	opcode, data, err := r.socket.ReadMessage(ctx)
	if err != nil {
		return nil, err
	}
	if opcode != webSocketOpcodeText {
		return nil, wireRT.ErrMalformedJSONFrame
	}
	frame, err := wireRT.DecodeJSONFrame(data, r.cfg)
	if err != nil {
		return nil, err
	}
	return []wireRT.Frame{frame}, nil
}

// WebSocketHandler serves the one realtime WebSocket path. The process context
// releases every hijacked socket on shutdown.
func (s RealtimeServer) WebSocketHandler(ctx context.Context) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc(WebSocketPath, func(w http.ResponseWriter, r *http.Request) {
		socket, err := upgradeWebSocket(w, r, limits.NativeFramePayloadMax)
		if err != nil {
			return
		}
		stopSocket := context.AfterFunc(ctx, func() { _ = socket.CloseNow() })
		defer stopSocket()
		defer socket.CloseNow()
		_ = s.ServeWebSocket(ctx, socket)
	})
	return mux
}

func (s RealtimeServer) ServeWebSocket(ctx context.Context, socket *webSocketConn) error {
	if socket == nil {
		return errors.New("nil realtime websocket")
	}
	cfg, policy, err := s.runtimeConfig()
	if err != nil {
		return err
	}
	source := &webSocketFrameSource{socket: socket, cfg: cfg}
	return s.serve(ctx, cfg, policy, source, func() (*connWriter, error) {
		return newFrameWriter(ctx, cfg, policy.WriteTimeout, wireRT.EncodeJSONFrame,
			func(writeContext context.Context, body []byte) error {
				writeContext, cancel := context.WithTimeout(writeContext, policy.WriteTimeout)
				defer cancel()
				return socket.WriteText(writeContext, body)
			},
			func() { _ = socket.CloseNow() })
	})
}
