package observability

import "context"

type Attribute struct {
	Key   string
	Value string
}
type SpanSpec struct {
	Name       string
	Attributes []Attribute
}
type Span interface {
	Event(string, ...Attribute)
	End(error)
}
type Tracer interface {
	Start(context.Context, SpanSpec) (context.Context, Span)
}
type nopSpan struct{}

func (nopSpan) Event(string, ...Attribute) {}
func (nopSpan) End(error)                  {}

type NopTracer struct{}

func (NopTracer) Start(ctx context.Context, _ SpanSpec) (context.Context, Span) {
	return ctx, nopSpan{}
}
