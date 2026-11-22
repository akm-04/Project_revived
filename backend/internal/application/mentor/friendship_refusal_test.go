package mentor

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestFriendshipRefusalMapsStockCodes(t *testing.T) {
	actor := identity.PlayerID(100001)
	applicant := identity.PlayerID(200001)
	for _, testCase := range []struct {
		name string
		err  error
		want int64
	}{
		{name: "blocked pair", err: socialrelation.ErrPairBlocked, want: 34014},
		{name: "actor list full", err: &socialrelation.FriendCapacityError{PlayerID: actor}, want: 34006},
		{name: "applicant list full", err: &socialrelation.FriendCapacityError{PlayerID: applicant}, want: 34007},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			var refusal *Refusal
			if err := friendshipRefusal(testCase.err, actor); !errors.As(err, &refusal) || refusal.Code != testCase.want {
				t.Fatalf("friendshipRefusal(%v) = %v, want refusal %d", testCase.err, err, testCase.want)
			}
		})
	}
	unrelated := errors.New("database unavailable")
	if err := friendshipRefusal(unrelated, actor); err != unrelated {
		t.Fatalf("unrelated error was mapped: %v", err)
	}
}
