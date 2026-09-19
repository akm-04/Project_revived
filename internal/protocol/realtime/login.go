package realtime

import (
	"errors"
	"fmt"
	"math"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

var ErrMalformedTCPLogin = errors.New("malformed TCP_LOGIN claims")

type LoginClaims struct {
	Token  string
	Region int64
	RoomID int64
}

func ParseTCPLogin(f Frame) (LoginClaims, error) {
	if f.MID != mids.MIDTCPLogin {
		return LoginClaims{}, ErrPreauthMID
	}
	o, ok := f.Params.(*amf3.Object)
	if !ok || o == nil {
		return LoginClaims{}, ErrMalformedTCPLogin
	}
	m, err := o.StrictMap()
	if err != nil {
		return LoginClaims{}, fmt.Errorf("%w: %v", ErrMalformedTCPLogin, err)
	}
	token, ok := m["token"].(string)
	if !ok || token == "" {
		return LoginClaims{}, fmt.Errorf("%w: token", ErrMalformedTCPLogin)
	}
	region, ok := strictInteger(m["region"])
	if !ok || region <= 0 {
		return LoginClaims{}, fmt.Errorf("%w: region", ErrMalformedTCPLogin)
	}
	room, ok := strictInteger(m["room_id"])
	if !ok || room <= 0 {
		return LoginClaims{}, fmt.Errorf("%w: room_id", ErrMalformedTCPLogin)
	}
	return LoginClaims{Token: token, Region: region, RoomID: room}, nil
}

func strictInteger(v any) (int64, bool) {
	switch x := v.(type) {
	case int32:
		return int64(x), true
	case int64:
		return x, true
	case int:
		return int64(x), true
	case float64:
		if math.IsNaN(x) || math.IsInf(x, 0) || math.Trunc(x) != x || x < math.MinInt64 || x > math.MaxInt64 {
			return 0, false
		}
		return int64(x), true
	default:
		return 0, false
	}
}
