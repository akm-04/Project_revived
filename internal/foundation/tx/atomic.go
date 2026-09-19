package tx

import "context"

// FactAppender is the shared transaction-binding mechanism for committed facts.
//
// T is a domain-owned immutable fact type. This interface deliberately defines
// no generic fact schema/table and no cross-domain payload envelope: each owner
// supplies its own persistence adapter and retains authority over its fact
// vocabulary. The only shared contract is that the append occurs on the same Tx
// as the canonical source effect and any durable obligations.
type FactAppender[T any] interface {
	AppendFactTx(context.Context, Tx, T) error
}
