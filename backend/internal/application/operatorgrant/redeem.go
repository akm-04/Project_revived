package operatorgrant

import (
	"context"
	"errors"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorcatalog"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	CommandRedeemCreate  = "redeem.create"
	CommandRedeemDisable = "redeem.disable"

	CodeRedeemExpiry    = "OPERATOR_REDEEM_EXPIRY"
	CodeRedeemCap       = "OPERATOR_REDEEM_CAP"
	CodeRedeemCode      = "OPERATOR_REDEEM_CODE"
	CodeRedeemCodeTaken = "OPERATOR_REDEEM_CODE_TAKEN"
	CodeRedeemUnknown   = "OPERATOR_REDEEM_UNKNOWN"
)

const MaxRedeemCodeLength = 256

// RedeemOwner is the redeem owner's operator create/disable port.
type RedeemOwner interface {
	OperatorCreateRedeemTx(context.Context, tx.Tx, appi5.AdminOperator, appi5.RedeemCreateRequest, operation.Context) (appi5.RedeemCreateResult, error)
	OperatorDisableRedeemTx(context.Context, tx.Tx, appi5.AdminOperator, string, operation.Context) (appi5.RedeemDisableResult, error)
}

// RedeemCommands applies redeem.create and redeem.disable on the operator bus.
type RedeemCommands struct {
	Catalogue operatorcatalog.Document
	Redeem    RedeemOwner
	LineCap   int64
}

type redeemCreatePayload struct {
	Code      string        `json:"code,omitempty"`
	Lines     []linePayload `json:"lines"`
	ExpiresAt *string       `json:"expires_at,omitempty"`
	TotalCap  *int64        `json:"total_cap,omitempty"`
}

type redeemDisablePayload struct {
	Code string `json:"code"`
}

func (commands RedeemCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{CommandRedeemCreate: commands.createHandler, CommandRedeemDisable: commands.disableHandler}
}

func (commands RedeemCommands) createHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload redeemCreatePayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
	}
	lines, err := validateLines(commands.Catalogue, commands.LineCap, payload.Lines)
	if err != nil {
		return nil, err
	}
	request := appi5.RedeemCreateRequest{Code: payload.Code, Lines: lines, TotalCap: payload.TotalCap}
	if payload.ExpiresAt != nil {
		parsed, err := time.Parse(time.RFC3339, *payload.ExpiresAt)
		if err != nil {
			return nil, operator.Refuse(CodeRedeemExpiry, "expires_at must be an RFC3339 instant", nil)
		}
		parsed = parsed.UTC()
		if !parsed.After(scope.Operation.StartedAt.UTC()) {
			return nil, operator.Refuse(CodeRedeemExpiry, "expires_at must be in the future", nil)
		}
		request.ExpiresAt = &parsed
	}
	if request.TotalCap != nil && *request.TotalCap <= 0 {
		return nil, operator.Refuse(CodeRedeemCap, "total_cap must be a positive count", nil)
	}
	if request.Code != "" && len(request.Code) > MaxRedeemCodeLength {
		return nil, operator.Refuse(CodeRedeemCode, "code must hold at most 256 characters", nil)
	}
	if commands.Redeem == nil {
		return nil, operator.ErrUnavailable
	}
	admin := appi5.AdminOperator{ID: command.Envelope.Principal, ReasonCode: command.Envelope.Reason}
	result, err := commands.Redeem.OperatorCreateRedeemTx(ctx, scope.Tx, admin, request, scope.Operation)
	if err != nil {
		if errors.Is(err, appi5.ErrRedeemCodeTaken) {
			return nil, operator.Refuse(CodeRedeemCodeTaken, "that redeem code already exists", nil)
		}
		return nil, err
	}
	return result, nil
}

func (commands RedeemCommands) disableHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	var payload redeemDisablePayload
	if err := decodePayload(command.Payload, &payload); err != nil {
		return nil, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
	}
	if payload.Code == "" || len(payload.Code) > MaxRedeemCodeLength {
		return nil, operator.Refuse(CodeRedeemCode, "code must hold one to 256 characters", nil)
	}
	if commands.Redeem == nil {
		return nil, operator.ErrUnavailable
	}
	admin := appi5.AdminOperator{ID: command.Envelope.Principal, ReasonCode: command.Envelope.Reason}
	result, err := commands.Redeem.OperatorDisableRedeemTx(ctx, scope.Tx, admin, payload.Code, scope.Operation)
	if err != nil {
		if errors.Is(err, appi5.ErrRedeemUnknown) {
			return nil, operator.Refuse(CodeRedeemUnknown, "that redeem code does not exist", nil)
		}
		return nil, err
	}
	return result, nil
}
