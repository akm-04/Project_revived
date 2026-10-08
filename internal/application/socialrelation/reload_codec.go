package socialrelation

import "gxb.local/backend/v2/internal/application/socialreloadref"

func DecodeReloadReference(raw string) (ReloadReference, error) {
	return socialreloadref.DecodeReloadReference(raw)
}
