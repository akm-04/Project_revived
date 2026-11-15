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
	"log"
	"strconv"
	"sync"
	"time"
)

// CHANNEL_CHAT_SENDER_RATE_V1 is a PRIVATE_POLICY per-socket send rate, not an
// original-server rule. It keeps one noisy sender from filling the global
// message slots that other players need.
const (
	ChannelChatSenderRatePolicyID = "CHANNEL_CHAT_SENDER_RATE_V1"
	defaultChatSenderInterval     = time.Second
	defaultChatSenderBurst        = 5
)

// ChannelChatPolicy is selected V2 capacity policy, not an original-server rate rule.
type ChannelChatPolicy struct {
	MaxMessages, GlobalWorkers, LocalWorkers, MaxHandles int
	PrepareWait, PublicationWait, CommandWait            time.Duration
	SenderInterval                                       time.Duration
	SenderBurst                                          int
}

func DefaultChannelChatPolicy(maxHandles int) ChannelChatPolicy {
	return ChannelChatPolicy{MaxMessages: 16, GlobalWorkers: 8, LocalWorkers: 8, MaxHandles: maxHandles, PrepareWait: 3 * time.Second, PublicationWait: 2 * time.Second, CommandWait: 5 * time.Second, SenderInterval: defaultChatSenderInterval, SenderBurst: defaultChatSenderBurst}
}

// ApplyEnv applies the optional PRIVATE_POLICY overrides. Absent variables keep
// the defaults; an invalid value is an error so a typo cannot silently change
// the rate.
func (p *ChannelChatPolicy) ApplyEnv(getenv func(string) string) error {
	if p == nil || getenv == nil {
		return nil
	}
	if value := getenv("GXB_CHANNEL_CHAT_SENDER_INTERVAL"); value != "" {
		interval, err := time.ParseDuration(value)
		if err != nil {
			return err
		}
		p.SenderInterval = interval
	}
	if value := getenv("GXB_CHANNEL_CHAT_SENDER_BURST"); value != "" {
		burst, err := strconv.Atoi(value)
		if err != nil {
			return err
		}
		p.SenderBurst = burst
	}
	return p.validate()
}

func (p ChannelChatPolicy) validate() error {
	if p.MaxMessages < 1 || p.MaxMessages > 16 || p.GlobalWorkers < 1 || p.GlobalWorkers > 8 || p.LocalWorkers < 1 || p.LocalWorkers > 8 || p.MaxHandles < 1 || p.PrepareWait <= 0 || p.PrepareWait > 3*time.Second || p.PublicationWait <= 0 || p.PublicationWait > 2*time.Second || p.CommandWait <= 0 || p.CommandWait > 5*time.Second || p.SenderInterval <= 0 || p.SenderBurst < 1 {
		return errors.New("invalid bounded channel chat policy")
	}
	return nil
}

// chatSenderBucket is one socket's allowance. The registry session owns it, so
// it lives and dies with that socket and needs no global keyed map.
type chatSenderBucket struct {
	mu     sync.Mutex
	tokens float64
	at     time.Time
}

func (b *chatSenderBucket) allow(at time.Time, interval time.Duration, burst int) bool {
	b.mu.Lock()
	defer b.mu.Unlock()
	if b.at.IsZero() {
		b.tokens = float64(burst)
	} else {
		b.tokens += float64(at.Sub(b.at)) / float64(interval)
		if b.tokens > float64(burst) {
			b.tokens = float64(burst)
		}
	}
	b.at = at
	if b.tokens < 1 {
		return false
	}
	b.tokens--
	return true
}

func (h SessionHandle) allowChatSender(at time.Time, interval time.Duration, burst int) bool {
	if h.session == nil {
		return false
	}
	return h.session.chatSender.allow(at, interval, burst)
}

type ChannelChatOutcome string

const (
	ChatTransportWriteRecorded ChannelChatOutcome = "TRANSPORT_WRITE_RECORDED"
	ChatIneligible             ChannelChatOutcome = "NOT_ATTEMPTED_INELIGIBLE"
	ChatBudget                 ChannelChatOutcome = "NOT_ATTEMPTED_BUDGET"
	ChatSendUnknown            ChannelChatOutcome = "SEND_OUTCOME_UNKNOWN_OR_ERROR"
	ChatSenderLimited          ChannelChatOutcome = "NOT_ATTEMPTED_SENDER_LIMITED"
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

type chatRecipientJob struct {
	recipient SessionHandle
	index     int
}

// authorizeOrdinaryRecipients authorizes every still-current recipient of one
// ordinary message from a single transaction. Handles that cannot admit the
// message at all stay false and are counted ineligible by the worker.
func (d *ChannelChatDispatcher) authorizeOrdinaryRecipients(ctx context.Context, handles []SessionHandle, exact apprealtime.Admission) ([]bool, error) {
	authorized := make([]bool, len(handles))
	admissions := make([]apprealtime.Admission, 0, len(handles))
	indexes := make([]int, 0, len(handles))
	for i, recipient := range handles {
		a, ok := recipient.Admission()
		if !ok || !d.Registry.IsCurrent(recipient) || a.Domain.Role != exact.Domain.Role || a.Domain.RoomID != exact.Domain.RoomID {
			continue
		}
		admissions = append(admissions, a)
		indexes = append(indexes, i)
	}
	if len(admissions) == 0 {
		return authorized, nil
	}
	verdicts, err := d.Service.AuthorizeRecipients(ctx, admissions)
	if err != nil {
		return nil, err
	}
	if len(verdicts) != len(admissions) {
		return nil, channelchat.ErrIncompleteRead
	}
	for position, verdict := range verdicts {
		authorized[indexes[position]] = verdict
	}
	return authorized, nil
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
	// D506: structured chat is active whenever production wiring supplies the
	// owner for the selected kind; an unwired kind stays silent but is logged.
	if r.Type != 0 && (ingress.Selector == nil || !d.Service.Owners.Available(channelchat.Kind(ingress.Selector.Kind))) {
		log.Printf("structured channel chat refused: type=%d channel=%d owner unavailable", r.Type, r.Channel)
		d.report(ChannelChatReport{ProviderGated: true})
		return nil, nil
	}
	// PRIVATE_POLICY CHANNEL_CHAT_SENDER_RATE_V1: the per-socket bucket is
	// consulted before a fan-out slot is taken, so a sender over its rate cannot
	// starve other senders of the global slots.
	if !h.allowChatSender(time.Now(), d.policy.SenderInterval, d.policy.SenderBurst) {
		d.report(ChannelChatReport{Outcomes: map[ChannelChatOutcome]int{ChatSenderLimited: 1}})
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
		// A foreign or missing owner reference is a silent refusal: the sender
		// keeps its session and no recipient sees a card.
		if errors.Is(err, channelchat.ErrInvalidStructured) || errors.Is(err, channelchat.ErrProviderUnavailable) {
			log.Printf("structured channel chat refused: type=%d channel=%d owner rejected reference", r.Type, r.Channel)
			d.report(ChannelChatReport{ProviderGated: true})
			return nil, nil
		}
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
	// Ordinary chat authorizes the whole recipient set with one read taken for
	// this message. Structured cards keep their per-recipient owner gate.
	var authorized []bool
	if r.Type == 0 {
		var authorizeErr error
		authorized, authorizeErr = d.authorizeOrdinaryRecipients(publication, handles, exact)
		if authorizeErr != nil {
			outcome := ChatIneligible
			if publication.Err() != nil {
				outcome = ChatBudget
			}
			for range handles {
				count(outcome)
			}
			d.report(report)
			return nil, nil
		}
	}
	jobs := make(chan chatRecipientJob)
	var joined sync.WaitGroup
	n := d.policy.LocalWorkers
	if len(handles) < n {
		n = len(handles)
	}
	for i := 0; i < n; i++ {
		joined.Add(1)
		go func() {
			defer joined.Done()
			for job := range jobs {
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
					recipient := job.recipient
					a, ok := recipient.Admission()
					if !ok || !d.Registry.IsCurrent(recipient) || a.Domain.Role != exact.Domain.Role || a.Domain.RoomID != exact.Domain.RoomID {
						return ChatIneligible
					}
					if authorized != nil {
						if !authorized[job.index] {
							return ChatIneligible
						}
					} else if err := d.Service.AuthorizeStructuredRecipient(publication, a, structured); err != nil {
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
		case jobs <- chatRecipientJob{recipient: recipient, index: i}:
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
	title, bubble := m.TitleInfo, m.BubbleInfo
	if title == "" {
		title = "@@@@"
	}
	if bubble == "" {
		bubble = "10001@0"
	}
	np, err := json.Marshal(map[string]any{"title_info": title, "bubble_info": bubble, "conquer_lev": m.ConquerLevel, "conquer_loop_id": m.ConquerLoopID})
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
