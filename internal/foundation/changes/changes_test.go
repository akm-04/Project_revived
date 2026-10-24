package changes

import (
	"context"
	"slices"
	"testing"
)

func TestOnlyKeptStagesReachTheRequest(t *testing.T) {
	ctx, request := Track(context.Background())
	aborted, _ := Stage(ctx)
	Balance(aborted, "crystal", 1)
	FunctionOpened(aborted, 9)
	committed, committedStage := Stage(ctx)
	Balance(committed, "crystal", 40)
	Balance(committed, "lev", 12)
	inner, innerStage := Stage(committed)
	FunctionOpened(inner, 7)
	innerStage.Keep()
	if balances, functions := Recorded(committed); balances["crystal"] != 40 || !slices.Equal(functions, []int64{7}) {
		t.Fatalf("recorded stage %v %v", balances, functions)
	}
	committedStage.Keep()
	if got := request.Balances(); len(got) != 2 || got["crystal"] != 40 || got["lev"] != 12 {
		t.Fatalf("balances %v", got)
	}
	if got := request.Functions(); !slices.Equal(got, []int64{7}) {
		t.Fatalf("functions %v", got)
	}
}

func TestUntrackedRequestRecordsNothing(t *testing.T) {
	ctx, stage := Stage(context.Background())
	if stage != nil {
		t.Fatal("stage without a tracked request")
	}
	Balance(ctx, "crystal", 1)
	FunctionOpened(ctx, 1)
	stage.Keep()
	if balances, functions := Recorded(ctx); len(balances) != 0 || functions != nil {
		t.Fatal("untracked recorded")
	}
}
