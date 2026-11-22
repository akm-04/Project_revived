package operatorgrant

import (
	"context"
	"encoding/json"
	"time"
	"unicode/utf8"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	CommandMailSend   = "mail.send"
	MailPolicyVersion = "operator-mail-v1"

	CodeMailTitle  = "OPERATOR_MAIL_TITLE"
	CodeMailBody   = "OPERATOR_MAIL_BODY"
	CodeMailExpire = "OPERATOR_MAIL_EXPIRE"
	CodeMailTarget = "OPERATOR_MAIL_TARGET"

	MaxMailTitleRunes = 64
	MaxMailBodyRunes  = 2000
)

// MailOwner is the i5 admin mail command: the job form opens its own
// transaction, the inline form reuses the bus transaction.
type MailOwner interface {
	AdminSendMail(context.Context, appi5.AdminOperator, identity.PlayerID, mail.Namespace, string, string, string, string, string, []grant.Line, *time.Time, *int64, operation.Context) (appi5.AdminMailResult, error)
	AdminSendMailTx(context.Context, tx.Tx, appi5.AdminOperator, identity.PlayerID, mail.Namespace, string, string, string, string, string, []grant.Line, *time.Time, *int64, operation.Context) (appi5.AdminMailResult, error)
}

// MailCommands applies mail.send on the operator bus with the shared bulk core.
type MailCommands struct {
	Catalogue operatorcatalog.Document
	Store     BulkStore
	Directory playerdirectory.OperatorRecipients
	Mail      MailOwner
	LineCap   int64
}

type mailExpirePayload struct {
	Fixed     *string `json:"fixed,omitempty"`
	AfterRead *int64  `json:"after_read,omitempty"`
	OnRead    *bool   `json:"on_read,omitempty"`
}

type mailPayload struct {
	Target      targetPayload     `json:"target"`
	Title       string            `json:"title"`
	Body        string            `json:"body"`
	Attachments []linePayload     `json:"attachments,omitempty"`
	Expire      mailExpirePayload `json:"expire"`
}

// mailDelivery is the frozen delivery every recipient receives.
type mailDelivery struct {
	Title     string
	Body      string
	Lines     []grant.Line
	Expires   *time.Time
	AfterRead *int64
}

func (commands MailCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{CommandMailSend: commands.sendHandler}
}

func (commands MailCommands) sendHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload mailPayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
	}
	delivery, err := buildMailDelivery(commands.Catalogue, commands.LineCap, payload, scope.Operation.StartedAt)
	if err != nil {
		return nil, err
	}
	selector, recipients, err := resolveTarget(ctx, scope.Tx, commands.Directory, payload.Target)
	if err != nil {
		return nil, err
	}
	if len(recipients) == 0 {
		return nil, operator.Refuse(CodeMailTarget, "the target matches no players", nil)
	}
	if commands.Mail == nil {
		return nil, operator.ErrUnavailable
	}
	admin := appi5.AdminOperator{ID: command.Envelope.Principal, ReasonCode: command.Envelope.Reason}
	if len(recipients) <= InlineRecipientLimit {
		return commands.applyInline(ctx, scope, admin, command.Envelope.SemanticKey, recipients, delivery)
	}
	if commands.Store == nil {
		return nil, operator.ErrUnavailable
	}
	target := BulkTarget{
		SemanticKey:     command.Envelope.SemanticKey,
		ModuleCommand:   command.ModuleCommand,
		Selector:        selector,
		PlayerIDs:       recipients,
		PlayerCount:     len(recipients),
		PlayerIDsSHA256: sha256IDs(recipients),
		Payload:         append(json.RawMessage(nil), command.Payload...),
		Principal:       command.Envelope.Principal,
		Reason:          command.Envelope.Reason,
		State:           StatePending,
		CreatedAt:       scope.Operation.StartedAt.UTC(),
		UpdatedAt:       scope.Operation.StartedAt.UTC(),
	}
	if err := commands.Store.InsertBulkTx(ctx, scope.Tx, target); err != nil {
		return nil, err
	}
	return GrantResult{Bulk: true, SemanticKey: target.SemanticKey, PlayerCount: target.PlayerCount, State: StatePending}, nil
}

func (commands MailCommands) applyInline(ctx context.Context, scope tx.Scope, admin appi5.AdminOperator, commandKey string, recipients []int64, delivery mailDelivery) (GrantResult, error) {
	result := GrantResult{SemanticKey: commandKey, PlayerCount: len(recipients), State: operator.StateApplied}
	for _, rawID := range recipients {
		_, err := commands.Mail.AdminSendMailTx(ctx, scope.Tx, admin, identity.PlayerID(rawID), mail.Normal, recipientKey(commandKey, rawID), delivery.Title, "GM", delivery.Body, MailPolicyVersion, delivery.Lines, delivery.Expires, delivery.AfterRead, scope.Operation)
		if err != nil {
			// A refused recipient rolls the whole command back; the same key
			// replays every recipient rather than leaving a partial mailbox.
			return GrantResult{}, err
		}
		result.Applied++
	}
	return result, nil
}

// buildMailDelivery validates the mail payload and freezes what every
// recipient receives. at is the submit time for the fixed-expiry future check.
func buildMailDelivery(catalogue operatorcatalog.Document, lineCap int64, payload mailPayload, at time.Time) (mailDelivery, error) {
	if !utf8.ValidString(payload.Title) || utf8.RuneCountInString(payload.Title) < 1 || utf8.RuneCountInString(payload.Title) > MaxMailTitleRunes {
		return mailDelivery{}, operator.Refuse(CodeMailTitle, "title must hold one to sixty-four characters", map[string]int{"max": MaxMailTitleRunes})
	}
	if !utf8.ValidString(payload.Body) || utf8.RuneCountInString(payload.Body) < 1 || utf8.RuneCountInString(payload.Body) > MaxMailBodyRunes {
		return mailDelivery{}, operator.Refuse(CodeMailBody, "body must hold one to two thousand characters", map[string]int{"max": MaxMailBodyRunes})
	}
	var lines []grant.Line
	if len(payload.Attachments) > 0 {
		validated, err := validateLines(catalogue, lineCap, payload.Attachments)
		if err != nil {
			return mailDelivery{}, err
		}
		lines = validated
	}
	expires, afterRead, err := deliveryExpiry(payload.Expire, at)
	if err != nil {
		return mailDelivery{}, err
	}
	return mailDelivery{Title: payload.Title, Body: payload.Body, Lines: lines, Expires: expires, AfterRead: afterRead}, nil
}

func deliveryExpiry(expire mailExpirePayload, at time.Time) (*time.Time, *int64, error) {
	forms := 0
	if expire.Fixed != nil {
		forms++
	}
	if expire.AfterRead != nil {
		forms++
	}
	if expire.OnRead != nil {
		forms++
	}
	if forms != 1 {
		return nil, nil, operator.Refuse(CodeMailExpire, "exactly one of fixed, after_read and on_read is required", nil)
	}
	if expire.Fixed != nil {
		fixed, err := time.Parse(time.RFC3339, *expire.Fixed)
		if err != nil {
			return nil, nil, operator.Refuse(CodeMailExpire, "fixed must be an RFC3339 instant", nil)
		}
		fixed = fixed.UTC()
		if at.IsZero() || !fixed.After(at.UTC()) {
			return nil, nil, operator.Refuse(CodeMailExpire, "fixed must be in the future", nil)
		}
		return &fixed, nil, nil
	}
	if expire.AfterRead != nil {
		if *expire.AfterRead < 0 {
			return nil, nil, operator.Refuse(CodeMailExpire, "after_read seconds cannot be negative", nil)
		}
		seconds := *expire.AfterRead
		return nil, &seconds, nil
	}
	if !*expire.OnRead {
		return nil, nil, operator.Refuse(CodeMailExpire, "on_read must be true when used", nil)
	}
	zero := int64(0)
	return nil, &zero, nil
}
