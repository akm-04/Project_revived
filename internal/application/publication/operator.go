package publication

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/identity"
	pub "gxb.local/backend/v2/internal/domain/publication"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	CodeFamilyInvalid     = "PUBLICATION_FAMILY"
	CodeRevisionConflict  = "PUBLICATION_REVISION_CONFLICT"
	defaultShowTimeLayout = time.RFC3339
)

// OperatorCommands installs and clears publication sets on the operator bus
// (I11A_OPERATOR_COMMANDS_V1 ruling: publication.install/clear).
type OperatorCommands struct {
	Store   Store
	Clock   func() time.Time
	NewUUID func() (ids.UUID, error)
}

func (commands OperatorCommands) now() time.Time {
	if commands.Clock == nil {
		return time.Now().UTC()
	}
	return commands.Clock().UTC()
}

func (commands OperatorCommands) mintUUID() (ids.UUID, error) {
	if commands.NewUUID == nil {
		return ids.NewUUID()
	}
	return commands.NewUUID()
}

// Module is the publication module: the two install commands and the show read.
func (commands OperatorCommands) Module() operator.Module {
	return operator.Module{
		ID:         "publication",
		Title:      "Publications",
		Role:       operator.RoleRoot,
		LogChannel: "publication",
		Screen:     operator.Screen{Tab: "Notices", Columns: []string{"family", "set_id", "server_id", "starts_at", "ends_at"}},
		Commands: []operator.CommandSpec{
			{Name: "publication.install", Class: operator.ClassLive, Help: "Install one revisioned set of one family; a new set id makes it visible at starts_at.", Fields: installFields(), Handler: commands.installHandler},
			{Name: "publication.clear", Class: operator.ClassLive, Help: "Install an empty set of the family so the client falls back to its defaults.", Fields: []operator.Field{
				operator.NewField("family", operator.FieldString, true, "publication family").WithEnum(pub.Announcement, pub.Board, pub.Picture),
				operator.NewField("server_id", operator.FieldInt, false, "logical server id; 0 (or omitted) is global"),
			}, Handler: commands.clearHandler},
		},
		Reads: []operator.Read{
			{Name: "publication.show", Help: "The set each family selects at the current time, with its id and schedule.", Fields: []operator.Field{
				operator.NewField("family", operator.FieldString, false, "family filter").WithEnum(pub.Announcement, pub.Board, pub.Picture),
				operator.NewField("server_id", operator.FieldInt, false, "logical server id; 0 (or omitted) is global"),
			}},
		},
	}
}

// Handlers registers both commands on the operator bus.
func (commands OperatorCommands) Handlers() map[string]operator.Handler {
	return map[string]operator.Handler{
		"publication.install": commands.installHandler,
		"publication.clear":   commands.clearHandler,
	}
}

func installFields() []operator.Field {
	return []operator.Field{
		operator.NewField("set_id", operator.FieldUUID, false, "set uuid; omitted mints one"),
		operator.NewField("family", operator.FieldString, true, "publication family").WithEnum(pub.Announcement, pub.Board, pub.Picture),
		operator.NewField("server_id", operator.FieldInt, false, "logical server id; must be 0 for the login notice"),
		operator.NewField("starts_at", operator.FieldString, false, "RFC3339 visible start; omitted is now"),
		operator.NewField("ends_at", operator.FieldString, false, "RFC3339 visible end; omitted never ends"),
		operator.NewField("announcement", operator.FieldObject, false, "login notice: {title, contents[], url}"),
		operator.NewField("pictures", operator.FieldArray, false, "lobby pictures: [{weight, pic, small_pic}]"),
		operator.NewField("board", operator.FieldArray, false, "Activities board: [{id, title, start_date, content, img_url}]"),
	}
}

type installPayload struct {
	SetID        string            `json:"set_id,omitempty"`
	Family       string            `json:"family"`
	ServerID     int64             `json:"server_id,omitempty"`
	StartsAt     string            `json:"starts_at,omitempty"`
	EndsAt       *string           `json:"ends_at,omitempty"`
	Announcement *pub.Section      `json:"announcement,omitempty"`
	Pictures     []pub.PictureItem `json:"pictures,omitempty"`
	Board        []pub.BoardItem   `json:"board,omitempty"`
}

type clearPayload struct {
	Family   string `json:"family"`
	ServerID int64  `json:"server_id,omitempty"`
}

// Set builds the domain set the payload describes.
func (payload installPayload) Set(setID ids.UUID, at time.Time) (pub.Set, error) {
	family, err := parseFamily(payload.Family)
	if err != nil {
		return pub.Set{}, err
	}
	startsAt := at.UTC()
	if payload.StartsAt != "" {
		startsAt, err = time.Parse(defaultShowTimeLayout, payload.StartsAt)
		if err != nil {
			return pub.Set{}, operator.Refuse(operator.CodePayloadInvalid, "starts_at must be RFC3339", nil)
		}
	}
	var endsAt *time.Time
	if payload.EndsAt != nil {
		parsed, err := time.Parse(defaultShowTimeLayout, *payload.EndsAt)
		if err != nil {
			return pub.Set{}, operator.Refuse(operator.CodePayloadInvalid, "ends_at must be RFC3339", nil)
		}
		endsAt = &parsed
	}
	items, err := payload.items(family)
	if err != nil {
		return pub.Set{}, err
	}
	return pub.Set{ID: setID, Family: family, ServerID: int32(payload.ServerID), StartsAt: startsAt, EndsAt: endsAt, Items: items}, nil
}

func (payload installPayload) items(family string) ([]pub.Item, error) {
	switch family {
	case pub.Announcement:
		if payload.Announcement == nil {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the login notice needs an announcement", nil)
		}
		return []pub.Item{{Announcement: payload.Announcement}}, nil
	case pub.Picture:
		if len(payload.Pictures) == 0 {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the lobby picture family needs at least one picture", nil)
		}
		items := make([]pub.Item, 0, len(payload.Pictures))
		for index := range payload.Pictures {
			items = append(items, pub.Item{Picture: &payload.Pictures[index]})
		}
		return items, nil
	default:
		if len(payload.Board) == 0 {
			return nil, operator.Refuse(operator.CodePayloadInvalid, "the Activities board family needs at least one entry", nil)
		}
		items := make([]pub.Item, 0, len(payload.Board))
		for index := range payload.Board {
			items = append(items, pub.Item{Board: &payload.Board[index]})
		}
		return items, nil
	}
}

func parseFamily(text string) (string, error) {
	switch text {
	case pub.Announcement, pub.Board, pub.Picture:
		return text, nil
	}
	return "", operator.Refuse(CodeFamilyInvalid, "family must be announcement, board or picture", nil)
}

func decodeOperatorPayload(payload json.RawMessage, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return operator.Refuse(operator.CodePayloadInvalid, "the payload does not match the command: "+err.Error(), nil)
	}
	return nil
}

func (commands OperatorCommands) installHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	return commands.Install(ctx, scope.Tx, command.Payload)
}

// Install validates the typed payload and installs the set in the caller's
// transaction.
func (commands OperatorCommands) Install(ctx context.Context, transaction tx.Tx, payload json.RawMessage) (FamilyView, error) {
	if commands.Store == nil {
		return FamilyView{}, operator.ErrUnavailable
	}
	var request installPayload
	if err := decodeOperatorPayload(payload, &request); err != nil {
		return FamilyView{}, err
	}
	var setID ids.UUID
	if request.SetID == "" {
		minted, err := commands.mintUUID()
		if err != nil {
			return FamilyView{}, err
		}
		setID = minted
	} else {
		parsed, err := ids.ParseUUID(request.SetID)
		if err != nil {
			return FamilyView{}, operator.Refuse(operator.CodePayloadInvalid, "set_id must be a uuid", nil)
		}
		setID = parsed
	}
	set, err := request.Set(setID, commands.now())
	if err != nil {
		return FamilyView{}, err
	}
	canonical, digest, err := set.Canonical()
	if err != nil {
		return FamilyView{}, operator.Refuse(operator.CodePayloadInvalid, "the publication set is invalid: "+err.Error(), nil)
	}
	if err := commands.Store.InstallTx(ctx, transaction, canonical, digest); err != nil {
		if errors.Is(err, pub.ErrRevisionConflict) {
			return FamilyView{}, operator.Refuse(CodeRevisionConflict, "this set id was installed with different content", nil)
		}
		if errors.Is(err, pub.ErrInvalid) {
			return FamilyView{}, operator.Refuse(operator.CodePayloadInvalid, err.Error(), nil)
		}
		return FamilyView{}, err
	}
	return setView(canonical, true), nil
}

func (commands OperatorCommands) clearHandler(ctx context.Context, scope tx.Scope, command operator.Command) (any, error) {
	return commands.Clear(ctx, scope.Tx, command.Payload)
}

// Clear installs an empty set of the family so the selected set becomes empty
// (the client falls back to its defaults) without deleting immutable history.
func (commands OperatorCommands) Clear(ctx context.Context, transaction tx.Tx, payload json.RawMessage) (FamilyView, error) {
	if commands.Store == nil {
		return FamilyView{}, operator.ErrUnavailable
	}
	var request clearPayload
	if err := decodeOperatorPayload(payload, &request); err != nil {
		return FamilyView{}, err
	}
	family, err := parseFamily(request.Family)
	if err != nil {
		return FamilyView{}, err
	}
	setID, err := commands.mintUUID()
	if err != nil {
		return FamilyView{}, err
	}
	set := pub.Set{ID: setID, Family: family, ServerID: int32(request.ServerID), StartsAt: commands.now(), Items: []pub.Item{}}
	canonical, digest, err := set.Canonical()
	if err != nil {
		return FamilyView{}, operator.Refuse(operator.CodePayloadInvalid, "the clear set is invalid: "+err.Error(), nil)
	}
	if err := commands.Store.InstallTx(ctx, transaction, canonical, digest); err != nil {
		return FamilyView{}, err
	}
	return setView(canonical, false), nil
}

// FamilyView is one publication.show entry.
type FamilyView struct {
	Family   string     `json:"family"`
	SetID    string     `json:"set_id"`
	ServerID int64      `json:"server_id"`
	StartsAt time.Time  `json:"starts_at"`
	EndsAt   *time.Time `json:"ends_at,omitempty"`
	Visible  bool       `json:"visible"`
	Items    []pub.Item `json:"items"`
}

// ShowReply is the publication.show reply.
type ShowReply struct {
	Families []FamilyView `json:"families"`
}

func setView(set pub.Set, visible bool) FamilyView {
	items := set.Items
	if items == nil {
		items = []pub.Item{}
	}
	return FamilyView{Family: set.Family, SetID: set.ID.String(), ServerID: int64(set.ServerID), StartsAt: set.StartsAt.UTC(), EndsAt: set.EndsAt, Visible: visible, Items: items}
}

// OperatorRead answers publication.show.
type OperatorRead struct {
	Runner     tx.Runner
	Operations operation.Factory
	Store      Store
	Clock      func() time.Time
}

func (read OperatorRead) Show(ctx context.Context, familyFilter string, serverID int64) (ShowReply, error) {
	if read.Store == nil || read.Runner.DB == nil {
		return ShowReply{}, operator.ErrUnavailable
	}
	if serverID < 0 {
		return ShowReply{}, operator.Refuse(operator.CodeReadInvalid, "server_id must be zero or positive", nil)
	}
	families := []string{pub.Announcement, pub.Board, pub.Picture}
	if familyFilter != "" {
		family, err := parseFamily(familyFilter)
		if err != nil {
			return ShowReply{}, err
		}
		families = []string{family}
	}
	at := time.Now().UTC()
	if read.Clock != nil {
		at = read.Clock().UTC()
	}
	current, err := read.Operations.New(policy.Set{})
	if err != nil {
		return ShowReply{}, err
	}
	reply := ShowReply{Families: make([]FamilyView, 0, len(families))}
	_, err = read.Runner.Run(ctx, current, readProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		for _, family := range families {
			view, visible, readErr := read.Store.SelectTx(ctx, scope.Tx, family, identity.LogicalServerID(serverID), at)
			if readErr != nil {
				return readErr
			}
			if view.ID.IsZero() {
				continue
			}
			reply.Families = append(reply.Families, setView(view, visible))
		}
		return nil
	})
	if err != nil {
		return ShowReply{}, err
	}
	return reply, nil
}

func readProfile() tx.Profile {
	return tx.Profile{Name: "operator-publication-show-v1", AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}
