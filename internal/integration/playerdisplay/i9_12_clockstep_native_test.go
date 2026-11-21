//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	d "gxb.local/backend/v2/internal/domain/privilege"
)

// BUGS #108: every commerce_privilege_roots row was created while the server
// clock was forwarded. After the clock returned to real time, MID 1 must still
// log in: a row whose CreatedAt and UpdatedAt are both after the decision time
// is a stale forward fact, not corruption.
func TestI9_12ClockStepLoginAcceptsRootCreatedUnderForwardClock(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	actor := bornActor(t, p)
	secret := []byte("i9-12-clockstep-native-digest-01")
	sidRaw, loginRaw := clockRollbackCredentials(t, p, actor, secret)

	at := time.Now().UTC().Truncate(time.Microsecond)
	forward := at.Add(8 * time.Hour)
	exec(t, p, `INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at)
VALUES($1,$2,0,0,'QUALIFIED_ABSENT',$3,$4,$5,'clockstep-native','clockstep-native',1,$6,$6)`,
		int64(actor.PlayerID), int64(actor.LogicalServerID), revision, d.ManualPolicy, d.ManualClass, forward)

	service := clockRollbackService(p, &i911cFixedClock{at: at}, secret)
	dispatcher := stockruntime.BootstrapDispatcher{Bootstrap: service}
	response := clockRollbackLogin(t, dispatcher, sidRaw, loginRaw, at, 7)
	if response.HTTPStatus >= 500 {
		t.Fatalf("forward-created privilege root broke login: status %d body %#v", response.HTTPStatus, response.Body)
	}
	if response.HTTPStatus != 200 {
		t.Fatalf("forward-created privilege root refused login: status %d body %#v", response.HTTPStatus, response.Body)
	}
	detail, ok := response.Body["detail"].(map[string]any)
	if !ok {
		t.Fatalf("detail %T", response.Body["detail"])
	}
	if _, ok := detail["17"].(map[string]any); !ok {
		t.Fatalf("detail 17 missing: %#v", detail)
	}
	if _, ok := detail["160"]; !ok {
		t.Fatalf("detail 160 missing: %#v", detail)
	}

	// The backward-step rewrite keeps the forward fact: a manual import at real
	// time stores max(now, stored UpdatedAt, stored CreatedAt) and login stays up.
	manual := privilegeService(p, p)
	request := cp.Import{PlayerID: actor.PlayerID, LogicalServerID: actor.LogicalServerID, CommandKey: uuid().String(), Charge: 100, MonthlyState: d.MonthlyAbsent}
	written, err := manual.ImportManual(ctx, authority(), request, opPinned(revision))
	if err != nil {
		t.Fatalf("manual privilege rewrite after a backward step: %v", err)
	}
	if written.State.UpdatedAt.Before(forward) || written.State.UpdatedAt.Before(written.State.CreatedAt) {
		t.Fatalf("rewrite moved the stored timestamps backwards: %+v", written.State)
	}
	stored, known, err := (ps.Store{}).ReadPrivilegeTx(ctx, p, actor.PlayerID, false)
	if err != nil || !known {
		t.Fatalf("stored privilege root %v %v", known, err)
	}
	if stored.UpdatedAt.Before(forward) || stored.UpdatedAt.Before(stored.CreatedAt) {
		t.Fatalf("stored timestamps after rewrite %+v", stored)
	}

	again := clockRollbackLogin(t, dispatcher, sidRaw, loginRaw, at, 8)
	if again.HTTPStatus != 200 {
		t.Fatalf("login after the rewrite: status %d body %#v", again.HTTPStatus, again.Body)
	}
}
