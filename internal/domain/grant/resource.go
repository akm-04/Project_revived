package grant

// ResourceGrantable is the one settlement rule for a content resource class and
// activation. The content runtime applies it per grant line, and the operator
// catalogue reports the same answer, so neither keeps a hand list.
func ResourceGrantable(class, activation string) (bool, string) {
	switch LineKind(class) {
	case ScalarCurrency, StackItem:
		if activation == "ENABLED_R4" {
			return true, ""
		}
	case PlayerExp, Temporal:
		if activation == "ENABLED_R5" {
			return true, ""
		}
	}
	if activation == "" {
		return false, class
	}
	return false, activation
}
