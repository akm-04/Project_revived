package stockruntime

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/application/channelchat"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	domainrt "gxb.local/backend/v2/internal/domain/realtimeauth"
	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
	wireRT "gxb.local/backend/v2/internal/protocol/realtime"
	"sync"
	"time"
)

// ChannelChatPolicy is selected V2 capacity policy, not an original-server rate rule.
type ChannelChatPolicy struct {
	MaxMessages, GlobalWorkers, LocalWorkers, MaxHandles int
	PrepareWait, PublicationWait, CommandWait            time.Duration
}

func DefaultChannelChatPolicy(maxHandles int) ChannelChatPolicy {
	return ChannelChatPolicy{16, 8, 8, maxHandles, 3 * time.Second, 2 * time.Second, 5 * time.Second}
}
func (p ChannelChatPolicy) validate() error {
	if p.MaxMessages < 1 || p.MaxMessages > 16 || p.GlobalWorkers < 1 || p.GlobalWorkers > 8 || p.LocalWorkers < 1 || p.LocalWorkers > 8 || p.MaxHandles < 1 || p.PrepareWait <= 0 || p.PrepareWait > 3*time.Second || p.PublicationWait <= 0 || p.PublicationWait > 2*time.Second || p.CommandWait <= 0 || p.CommandWait > 5*time.Second {
		return errors.New("invalid bounded channel chat policy")
	}
	return nil
}

type ChannelChatOutcome string

const (
	ChatTransportWriteRecorded ChannelChatOutcome = "TRANSPORT_WRITE_RECORDED"
	ChatIneligible             ChannelChatOutcome = "NOT_ATTEMPTED_INELIGIBLE"
	ChatBudget                 ChannelChatOutcome = "NOT_ATTEMPTED_BUDGET"
	ChatSendUnknown            ChannelChatOutcome = "SEND_OUTCOME_UNKNOWN_OR_ERROR"
)

// ChannelChatReport is aggregate ephemeral telemetry. It retains neither text nor token.
type ChannelChatReport struct {
	Outcomes                                   map[ChannelChatOutcome]int
	Saturated, SnapshotOverflow, ProviderGated bool
}
type ChannelChatDispatcher struct {
	Registry          *ConnectionRegistry
	Service           channelchat.Service
	Publisher         RealtimePublisher
	policy            ChannelChatPolicy
	OnReport          func(ChannelChatReport)
	messages, workers chan struct{}
	structuredEnabled bool // no production setter or constructor activation; future owner activation requires a new selected seal
}

func NewChannelChatDispatcher(reg *ConnectionRegistry, service channelchat.Service, publisher RealtimePublisher, p ChannelChatPolicy) (*ChannelChatDispatcher, error) {
	if reg == nil || service.Reader == nil || service.Runner.DB == nil || service.Operations.Clock == nil {
		return nil, errors.New("incomplete channel chat wiring")
	}
	if err := p.validate(); err != nil {
		return nil, err
	}
	return &ChannelChatDispatcher{Registry: reg, Service: service, Publisher: publisher, policy: p, messages: make(chan struct{}, p.MaxMessages), workers: make(chan struct{}, p.GlobalWorkers)}, nil
}
func (d *ChannelChatDispatcher) report(r ChannelChatReport) {
	if d.OnReport != nil {
		d.OnReport(r)
	}
}
func channelForRole(role domainrt.PhysicalRole) int64 {
	switch role {
	case domainrt.World:
		return 0
	case domainrt.Guild:
		return 2
	case domainrt.Service:
		return 4
	}
	return -1
}
func sameAdmission(a, b apprealtime.Admission) bool {
	if a.Domain != b.Domain {
		return false
	}
	if a.GuildBinding == nil || b.GuildBinding == nil {
		return a.GuildBinding == nil && b.GuildBinding == nil
	}
	return *a.GuildBinding == *b.GuildBinding
}
func (d *ChannelChatDispatcher) HandleSessionClientFrame(ctx context.Context, h SessionHandle, admitted apprealtime.Admission, f wireRT.Frame) ([]wireRT.Frame, error) {
	if f.MID != mids.MIDSendChatMessage {
		return nil, ErrUnsupportedRealtimeMID
	}
	ingress, err := wireRT.ParseChannelChatIngress(f.Params)
	r := ingress.Request
	if err != nil {
		return nil, err
	}
	exact, ok := h.Admission()
	if !ok || !sameAdmission(exact, admitted) || !d.Registry.IsCurrent(h) || r.Channel != channelForRole(exact.Domain.Role) || r.HasRegion && r.Region != int64(exact.Domain.Actor.LogicalServerID) {
		return nil, ErrInvalidRealtimeSession
	}
	if r.Type != 0 && (!d.structuredEnabled || ingress.Selector == nil || !d.Service.Owners.Available(channelchat.Kind(ingress.Selector.Kind))) {
		d.report(ChannelChatReport{ProviderGated: true})
		return nil, nil
	}
	select {
	case d.messages <- struct{}{}:
		defer func() { <-d.messages }()
	default:
		d.report(ChannelChatReport{Saturated: true})
		return nil, nil
	}
	command, cancel := context.WithTimeout(ctx, d.policy.CommandWait)
	defer cancel()
	if err := command.Err(); err != nil {
		return nil, err
	}
	handles, within := d.Registry.ByRoomRoleBounded(exact.Domain.RoomID, exact.Domain.Role, d.policy.MaxHandles)
	if !within {
		d.report(ChannelChatReport{SnapshotOverflow: true})
		return nil, nil
	}
	prep, stop := context.WithTimeout(command, d.policy.PrepareWait)
	var value playerpresentation.Minimal
	var structured channelchat.PreparedStructured
	if r.Type == 0 {
		value, err = d.Service.Prepare(prep, exact, r.Message)
	} else {
		structured, err = d.Service.PrepareStructured(prep, exact, semanticStructuredSelector(*ingress.Selector))
		value = structured.Sender
	}
	stop()
	if err != nil {
		return nil, err
	}
	if !d.Registry.IsCurrent(h) {
		return nil, ErrRealtimeSessionRetired
	}
	message := r.Message
	if r.Type != 0 {
		message, err = wireRT.ProjectStructuredMessage(wireStructuredValue(structured.Message), r.Channel)
		if err != nil {
			return nil, err
		}
	}
	params, err := chatPayload(value, message, r.Type)
	if err != nil {
		return nil, err
	}
	// Validate the immutable frame once before any partial publication can occur.
	if err := d.Publisher.Registry.ValidateDirect(mids.MIDChatMessage, protocolRole(exact.Domain.Role), params); err != nil {
		return nil, err
	}
	publication, end := context.WithTimeout(command, d.policy.PublicationWait)
	defer end()
	report := ChannelChatReport{Outcomes: make(map[ChannelChatOutcome]int)}
	var mu sync.Mutex
	count := func(o ChannelChatOutcome) { mu.Lock(); report.Outcomes[o]++; mu.Unlock() }
	jobs := make(chan SessionHandle)
	var joined sync.WaitGroup
	n := d.policy.LocalWorkers
	if len(handles) < n {
		n = len(handles)
	}
	for i := 0; i < n; i++ {
		joined.Add(1)
		go func() {
			defer joined.Done()
			for recipient := range jobs {
				if publication.Err() != nil {
					count(ChatBudget)
					continue
				}
				select {
				case d.workers <- struct{}{}:
				case <-publication.Done():
					count(ChatBudget)
					continue
				}
				outcome := func() ChannelChatOutcome {
					defer func() { <-d.workers }()
					a, ok := recipient.Admission()
					if !ok || !d.Registry.IsCurrent(recipient) || a.Domain.Role != exact.Domain.Role || a.Domain.RoomID != exact.Domain.RoomID {
						return ChatIneligible
					}
					authorize := func() error {
						if r.Type == 0 {
							return d.Service.AuthorizeRecipient(publication, a)
						}
						return d.Service.AuthorizeStructuredRecipient(publication, a, structured)
					}
					if err := authorize(); err != nil {
						if publication.Err() != nil {
							return ChatBudget
						}
						return ChatIneligible
					}
					if !d.Registry.IsCurrent(recipient) {
						return ChatIneligible
					}
					if publication.Err() != nil {
						return ChatBudget
					}
					if err := d.Publisher.PublishDirect(publication, recipient, mids.MIDChatMessage, params); err != nil {
						return ChatSendUnknown
					}
					return ChatTransportWriteRecorded
				}()
				count(outcome)
			}
		}()
	}
sendLoop:
	for i, recipient := range handles {
		select {
		case jobs <- recipient:
		case <-publication.Done():
			for range handles[i:] {
				count(ChatBudget)
			}
			break sendLoop
		}
	}
	close(jobs)
	joined.Wait()
	d.report(report)
	// Self echo was eligible only through the same fanout gate. No direct ACK/response.
	return nil, nil
}
func ordinaryChatPayload(m playerpresentation.Minimal, message string) (*amf3.Object, error) {
	if err := m.Validate(); err != nil {
		return nil, err
	}
	if err := channelchat.ValidateMessage(message); err != nil {
		return nil, err
	}
	return chatPayload(m, message, 0)
}
func chatPayload(m playerpresentation.Minimal, message string, kind int64) (*amf3.Object, error) {
	if err := m.Validate(); err != nil {
		return nil, err
	}
	for _, n := range []int64{int64(m.PlayerID), m.PlayerType, m.Level, m.AvatarID, m.AvatarFrameID, m.ConquerLevel, m.ConquerLoopID} {
		if !wireRT.IsExactChatNumber(n) {
			return nil, wireRT.ErrInvalidS2CPayload
		}
	}
	np, err := json.Marshal(map[string]any{"title_info": "@@@@", "bubble_info": "10001@0", "conquer_lev": m.ConquerLevel, "conquer_loop_id": m.ConquerLoopID})
	if err != nil {
		return nil, err
	}
	obj := &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: float64(m.PlayerID)}, {Name: "player_name", Value: m.Name}, {Name: "message", Value: message}, {Name: "player_type", Value: float64(m.PlayerType)}, {Name: "type", Value: float64(kind)}, {Name: "avatar_id", Value: float64(m.AvatarID)}, {Name: "avatar_frame_id", Value: float64(m.AvatarFrameID)}, {Name: "lev", Value: float64(m.Level)}, {Name: "np_info", Value: string(np)}}}
	if err := wireRT.ValidateChannelChat(obj); err != nil {
		return nil, err
	}
	return obj, nil
}

var _ SessionClientFrameDispatcher = (*ChannelChatDispatcher)(nil)
