//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	osexec "os/exec"
	"path/filepath"
	"testing"
	"time"
)

type conquerKillInput struct {
	Actor     identity.ActorContext
	Operation operation.Context
	Revision  string
}

func TestI7C2JProcessHelper(t *testing.T) {
	file := os.Getenv("GXB_I7C2J_KILL_INPUT")
	if file == "" {
		t.Skip("child only")
	}
	raw, e := os.ReadFile(file)
	if e != nil {
		t.Fatal(e)
	}
	var in conquerKillInput
	if e = json.Unmarshal(raw, &in); e != nil {
		t.Fatal(e)
	}
	p := pool(t)
	_, e = conquerFixtureWrite(p, &libraryKillDB{Beginner: p, at: 1, file: file + ".ready", committed: os.Getenv("GXB_I7C2J_COMMIT") == "1"}, in.Actor, in.Revision, in.Operation, 20, 1, false, nil)
	t.Fatal("returned past kill boundary", e)
}
func TestI7C2JProcessKillReopenCallerReceiptAndFoundation(t *testing.T) {
	p := pool(t)
	exe, e := os.Executable()
	if e != nil {
		t.Fatal(e)
	}
	for _, committed := range []bool{false, true} {
		a, rev, s := conquerFixture(t, p)
		in := conquerKillInput{Actor: a, Revision: rev, Operation: opPinned(rev)}
		raw, _ := json.Marshal(in)
		file := filepath.Join(t.TempDir(), "conquer-kill.json")
		if e = os.WriteFile(file, raw, 0600); e != nil {
			t.Fatal(e)
		}
		flag := "0"
		if committed {
			flag = "1"
		}
		cmd := osexec.Command(exe, "-test.run=^TestI7C2JProcessHelper$", "-test.v")
		cmd.Env = append(os.Environ(), "GXB_I7C2J_KILL_INPUT="+file, "GXB_I7C2J_COMMIT="+flag)
		var log bytes.Buffer
		cmd.Stdout = &log
		cmd.Stderr = &log
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
		ready := false
		for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
			if _, e = os.Stat(file + ".ready"); e == nil {
				ready = true
				break
			}
			time.Sleep(20 * time.Millisecond)
		}
		cmd.Process.Kill()
		cmd.Wait()
		if !ready {
			t.Fatal("killboundary", log.String())
		}
		before, e := (conquerstore.Store{}).ReadFactsTx(ctx, p, a.PlayerID)
		want := int64(1)
		if committed {
			want = 2
		}
		if e != nil || before.Version != want {
			t.Fatal(before, e, want)
		}
		reopened := pool(t)
		r, e := conquerFixtureWrite(reopened, reopened, a, rev, in.Operation, 20, 1, false, nil)
		if e != nil || r.Outcome != tx.DefiniteCommit {
			t.Fatal(r, e)
		}
		v, e := conquerRead(t, reopened, s, a, rev, 1)
		if e != nil || v.Observation.Facts.Version != 2 || v.Observation.Contributions[5] != 100 {
			t.Fatal(v, e)
		}
		t.Log("Caller fixture receipt andfoundation surviveSIGKILL; genuine5Eproducer notqualified", committed)
	}
}
