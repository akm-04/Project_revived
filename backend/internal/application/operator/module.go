package operator

import (
	"context"
	"fmt"
	"net/url"
	"regexp"
)

// Class is the live or maintenance class every command carries
// (I11A_ARCHITECTURE_V1 section 5).
type Class string

const (
	ClassLive        Class = "live"
	ClassMaintenance Class = "maintenance"
)

// Field kinds the GUI renders from (I11A_ARCHITECTURE_V1 section 2).
const (
	FieldString   = "string"
	FieldInt      = "int"
	FieldBool     = "bool"
	FieldObject   = "object"
	FieldArray    = "array"
	FieldDuration = "duration"
	FieldUUID     = "uuid"
)

// Route values say who runs a command: the backend bus or the agent itself.
const (
	RouteBackend = "backend"
	RouteAgent   = "agent"
)

// Field is one payload or query field of a command or read.
type Field struct {
	Name     string   `json:"name"`
	Type     string   `json:"type"`
	Required bool     `json:"required"`
	Minimum  *int64   `json:"minimum,omitempty"`
	Maximum  *int64   `json:"maximum,omitempty"`
	Enum     []string `json:"enum,omitempty"`
	Default  any      `json:"default,omitempty"`
	Help     string   `json:"help,omitempty"`
}

// NewField starts one field declaration.
func NewField(name, kind string, required bool, help string) Field {
	return Field{Name: name, Type: kind, Required: required, Help: help}
}

// Bounded adds the inclusive numeric bounds.
func (field Field) Bounded(minimum, maximum int64) Field {
	field.Minimum, field.Maximum = &minimum, &maximum
	return field
}

// WithEnum adds the accepted values.
func (field Field) WithEnum(values ...string) Field {
	field.Enum = values
	return field
}

// WithDefault records the factory default (F1, F3, F4).
func (field Field) WithDefault(value any) Field {
	field.Default = value
	return field
}

// DefaultValues collects each field's factory default.
func DefaultValues(fields []Field) map[string]any {
	values := make(map[string]any, len(fields))
	for _, field := range fields {
		if field.Default != nil {
			values[field.Name] = field.Default
		}
	}
	return values
}

// ReadHandler answers one bounded read from its query values.
type ReadHandler func(context.Context, url.Values) (any, error)

// Command is one typed command entry. Handler is nil until BindCommands fills
// it, and stays nil for a planned command.
type CommandSpec struct {
	Name    string   `json:"name"`
	Class   Class    `json:"class"`
	Fields  []Field  `json:"fields"`
	Help    string   `json:"help,omitempty"`
	Route   string   `json:"route,omitempty"`
	AnyOf   []string `json:"any_of,omitempty"`
	Handler Handler  `json:"-"`
}

// Read is one bounded read entry. Handler is nil until BindReads fills it.
type Read struct {
	Name    string      `json:"name"`
	Fields  []Field     `json:"fields"`
	Help    string      `json:"help,omitempty"`
	AnyOf   []string    `json:"any_of,omitempty"`
	Handler ReadHandler `json:"-"`
}

// Defaults is the factory default of a module's tunables and its reset path
// (F1, F3, F4), or why the module has none.
type Defaults struct {
	Values       map[string]any `json:"values,omitempty"`
	ResetCommand string         `json:"reset_command,omitempty"`
	None         string         `json:"none,omitempty"`
}

// Screen is the GUI hint of one module (O5): its tab and the columns of its
// list reads.
type Screen struct {
	Tab     string   `json:"tab,omitempty"`
	Columns []string `json:"columns,omitempty"`
}

// Module is one subsystem registered at start in both binaries
// (I11A_ARCHITECTURE_V1 section 2). Planned is the reason a module has no
// handler yet; its commands and reads are declarations only and cannot run.
type Module struct {
	ID         string        `json:"id"`
	Title      string        `json:"title"`
	Role       string        `json:"role,omitempty"`
	Commands   []CommandSpec `json:"commands"`
	Reads      []Read        `json:"reads"`
	Defaults   *Defaults     `json:"defaults,omitempty"`
	Screen     Screen        `json:"screen,omitempty"`
	LogChannel string        `json:"log_channel,omitempty"`
	Planned    string        `json:"planned,omitempty"`
}

var moduleIDPattern = regexp.MustCompile(`^[a-z][a-z0-9_.]*$`)

// Registry is the derived command and read surface. It is fail closed: a
// command that no module registered has no handler.
type Registry struct {
	modules  []Module
	handlers map[string]Handler
	reads    map[string]ReadHandler
}

// NewRegistry validates the module list and derives the handler maps. A
// non-planned command or read without a handler is refused, so a module cannot
// become callable half-declared.
func NewRegistry(modules ...Module) (Registry, error) {
	seenIDs := make(map[string]struct{}, len(modules))
	handlers := make(map[string]Handler)
	reads := make(map[string]ReadHandler)
	for _, module := range modules {
		if !moduleIDPattern.MatchString(module.ID) {
			return Registry{}, fmt.Errorf("operator: module id %q is not lowercase", module.ID)
		}
		if _, duplicate := seenIDs[module.ID]; duplicate {
			return Registry{}, fmt.Errorf("operator: module %q is registered twice", module.ID)
		}
		seenIDs[module.ID] = struct{}{}
		if err := module.validate(); err != nil {
			return Registry{}, err
		}
		if module.Planned != "" {
			continue
		}
		for _, command := range module.Commands {
			if command.Handler == nil {
				return Registry{}, fmt.Errorf("operator: command %q has no handler", command.Name)
			}
			if _, duplicate := handlers[command.Name]; duplicate {
				return Registry{}, fmt.Errorf("operator: command %q is registered twice", command.Name)
			}
			handlers[command.Name] = command.Handler
		}
		for _, read := range module.Reads {
			if read.Handler == nil {
				return Registry{}, fmt.Errorf("operator: read %q has no handler", read.Name)
			}
			if _, duplicate := reads[read.Name]; duplicate {
				return Registry{}, fmt.Errorf("operator: read %q is registered twice", read.Name)
			}
			reads[read.Name] = read.Handler
		}
	}
	return Registry{modules: cloneModules(modules), handlers: handlers, reads: reads}, nil
}

// Handlers returns a copy of the derived command handlers.
func (registry Registry) Handlers() map[string]Handler {
	copied := make(map[string]Handler, len(registry.handlers))
	for name, handler := range registry.handlers {
		copied[name] = handler
	}
	return copied
}

// Reads returns a copy of the derived read handlers.
func (registry Registry) Reads() map[string]ReadHandler {
	copied := make(map[string]ReadHandler, len(registry.reads))
	for name, handler := range registry.reads {
		copied[name] = handler
	}
	return copied
}

// Modules returns the module list the module route serves, planned rows
// included.
func (registry Registry) Modules() []Module {
	return cloneModules(registry.modules)
}

// BindCommands attaches the handlers of declared commands. A handler for a
// name the module did not declare is refused: that command would be callable
// without being in the registry.
func (module Module) BindCommands(handlers map[string]Handler) (Module, error) {
	for name, handler := range handlers {
		index := commandIndex(module.Commands, name)
		if index < 0 {
			return Module{}, fmt.Errorf("operator: command %q is not declared by module %q", name, module.ID)
		}
		module.Commands[index].Handler = handler
	}
	return module, nil
}

// BindReads attaches the handlers of declared reads, with the same fail-closed
// rule as BindCommands.
func (module Module) BindReads(handlers map[string]ReadHandler) (Module, error) {
	for name, handler := range handlers {
		index := readIndex(module.Reads, name)
		if index < 0 {
			return Module{}, fmt.Errorf("operator: read %q is not declared by module %q", name, module.ID)
		}
		module.Reads[index].Handler = handler
	}
	return module, nil
}

// MergeModules overlays local modules onto the backend's list. A module with
// the same id is merged: commands and reads with the same name come from the
// overlay, the rest are kept; a new id is appended. The agent uses it so its
// own ota commands join the backend ota module instead of hiding its entries.
func MergeModules(base, overlay []Module) []Module {
	merged := cloneModules(base)
	for _, module := range overlay {
		index := moduleIndex(merged, module.ID)
		if index < 0 {
			merged = append(merged, cloneModule(module))
			continue
		}
		merged[index] = mergeModule(merged[index], module)
	}
	return merged
}

func mergeModule(base, overlay Module) Module {
	if overlay.Title != "" {
		base.Title = overlay.Title
	}
	if overlay.Role != "" {
		base.Role = overlay.Role
	}
	if overlay.LogChannel != "" {
		base.LogChannel = overlay.LogChannel
	}
	if overlay.Screen.Tab != "" || len(overlay.Screen.Columns) > 0 {
		base.Screen = overlay.Screen
	}
	if overlay.Defaults != nil {
		base.Defaults = overlay.Defaults
	}
	if base.Planned == "" {
		base.Planned = overlay.Planned
	}
	for _, command := range overlay.Commands {
		if index := commandIndex(base.Commands, command.Name); index >= 0 {
			base.Commands[index] = command
			continue
		}
		base.Commands = append(base.Commands, command)
	}
	for _, read := range overlay.Reads {
		if index := readIndex(base.Reads, read.Name); index >= 0 {
			base.Reads[index] = read
			continue
		}
		base.Reads = append(base.Reads, read)
	}
	return base
}

func (module Module) validate() error {
	if module.Title == "" {
		return fmt.Errorf("operator: module %q has no title", module.ID)
	}
	for _, command := range module.Commands {
		if !moduleOwns(module.ID, command.Name) {
			return fmt.Errorf("operator: command %q is not in module %q", command.Name, module.ID)
		}
		switch command.Class {
		case ClassLive, ClassMaintenance:
		default:
			return fmt.Errorf("operator: command %q has class %q", command.Name, command.Class)
		}
		if err := validateFields(command.Name, command.Fields, command.AnyOf); err != nil {
			return err
		}
	}
	for _, read := range module.Reads {
		if !moduleOwns(module.ID, read.Name) {
			return fmt.Errorf("operator: read %q is not in module %q", read.Name, module.ID)
		}
		if err := validateFields(read.Name, read.Fields, read.AnyOf); err != nil {
			return err
		}
	}
	return nil
}

func moduleOwns(id, name string) bool {
	return len(name) > len(id) && name[:len(id)] == id && name[len(id)] == '.'
}

func validateFields(owner string, fields []Field, anyOf []string) error {
	seen := make(map[string]struct{}, len(fields))
	for _, field := range fields {
		if field.Name == "" || field.Type == "" {
			return fmt.Errorf("operator: %q has a field without a name or type", owner)
		}
		if _, duplicate := seen[field.Name]; duplicate {
			return fmt.Errorf("operator: %q declares field %q twice", owner, field.Name)
		}
		seen[field.Name] = struct{}{}
		if field.Minimum != nil && field.Maximum != nil && *field.Minimum > *field.Maximum {
			return fmt.Errorf("operator: %q field %q has minimum above maximum", owner, field.Name)
		}
	}
	for _, name := range anyOf {
		if _, declared := seen[name]; !declared {
			return fmt.Errorf("operator: %q any_of names undeclared field %q", owner, name)
		}
	}
	return nil
}

func commandIndex(commands []CommandSpec, name string) int {
	for index, command := range commands {
		if command.Name == name {
			return index
		}
	}
	return -1
}

func readIndex(reads []Read, name string) int {
	for index, read := range reads {
		if read.Name == name {
			return index
		}
	}
	return -1
}

func moduleIndex(modules []Module, id string) int {
	for index, module := range modules {
		if module.ID == id {
			return index
		}
	}
	return -1
}

func cloneModules(modules []Module) []Module {
	cloned := make([]Module, len(modules))
	for index, module := range modules {
		cloned[index] = cloneModule(module)
	}
	return cloned
}

func cloneModule(module Module) Module {
	module.Commands = append([]CommandSpec(nil), module.Commands...)
	module.Reads = append([]Read(nil), module.Reads...)
	module.Screen.Columns = append([]string(nil), module.Screen.Columns...)
	return module
}
