//go:build postgres

package playerdisplay_test

import (
	"net/http"
	"reflect"
	"testing"
)

func TestA128AwakeningComposeThroughProductionDispatcher(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	dispatcher := a128ComposeDispatcher(t, p, a)

	// Small Skull: 60 Skull Coupons and 10000 Mana produce one stack.
	a128Stack(t, p, a, 60001057, 60)
	a128SetMana(t, p, a, 100000)
	first := op()
	got := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50001070, 1, first))
	if got.HTTPStatus != http.StatusOK {
		t.Fatalf("awakening compose status=%d body=%#v", got.HTTPStatus, got.Body)
	}
	if quantity := a128Quantity(t, p, a, 50001070); quantity != 1 {
		t.Fatalf("target quantity=%d", quantity)
	}
	if quantity := a128Quantity(t, p, a, 60001057); quantity != 0 {
		t.Fatalf("coupon quantity=%d", quantity)
	}
	if mana := a128Mana(t, p, a); mana != 90000 {
		t.Fatalf("mana after compose=%d", mana)
	}

	replay := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50001070, 1, first))
	if replay.HTTPStatus != http.StatusOK || !reflect.DeepEqual(replay.Body, got.Body) {
		t.Fatalf("replay status=%d body=%#v first=%#v", replay.HTTPStatus, replay.Body, got.Body)
	}
	if quantity := a128Quantity(t, p, a, 50001070); quantity != 1 {
		t.Fatalf("replay granted again: %d", quantity)
	}
	if mana := a128Mana(t, p, a); mana != 90000 {
		t.Fatalf("replay debited again: %d", mana)
	}

	// item_num scales the coupon and Mana cost.
	a128Stack(t, p, a, 60001057, 120)
	a128SetMana(t, p, a, 100000)
	if scaled := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50001070, 2, op())); scaled.HTTPStatus != http.StatusOK {
		t.Fatalf("scaled compose status=%d body=%#v", scaled.HTTPStatus, scaled.Body)
	}
	if quantity := a128Quantity(t, p, a, 50001070); quantity != 3 {
		t.Fatalf("scaled target quantity=%d", quantity)
	}
	if mana := a128Mana(t, p, a); mana != 80000 {
		t.Fatalf("scaled mana=%d", mana)
	}

	// Fewer than 60 coupons is a typed refusal and settles nothing.
	a128Stack(t, p, a, 60001057, 59)
	a128SetMana(t, p, a, 100000)
	refused := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50001070, 1, op()))
	if refused.HTTPStatus != http.StatusConflict || refused.Body["error_code"] != int64(35028) {
		t.Fatalf("short components status=%d body=%#v", refused.HTTPStatus, refused.Body)
	}
	if quantity := a128Quantity(t, p, a, 50001070); quantity != 3 {
		t.Fatalf("refused compose granted: %d", quantity)
	}
	if mana := a128Mana(t, p, a); mana != 100000 {
		t.Fatalf("refused compose debited mana: %d", mana)
	}

	// Blood-awakening materials share the same rule (Ancestor's Spirit).
	a128Stack(t, p, a, 60005001, 240)
	a128SetMana(t, p, a, 180000)
	if blood := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50005001, 1, op())); blood.HTTPStatus != http.StatusOK {
		t.Fatalf("blood awakening compose status=%d body=%#v", blood.HTTPStatus, blood.Body)
	}
	if quantity := a128Quantity(t, p, a, 50005001); quantity != 1 {
		t.Fatalf("blood target quantity=%d", quantity)
	}
	if quantity := a128Quantity(t, p, a, 60005001); quantity != 0 {
		t.Fatalf("blood coupon quantity=%d", quantity)
	}
	if mana := a128Mana(t, p, a); mana != 0 {
		t.Fatalf("blood mana=%d", mana)
	}

	// An activity skin dot is type 4 but has no compiled recipe; it stays refused.
	if dot := dispatcher.Dispatch(ctx, a128ComposeRequest(t, a, 50001433, 1, op())); dot.HTTPStatus != http.StatusConflict || dot.Body["error_code"] != int64(35028) {
		t.Fatalf("skin dot status=%d body=%#v", dot.HTTPStatus, dot.Body)
	}
}
