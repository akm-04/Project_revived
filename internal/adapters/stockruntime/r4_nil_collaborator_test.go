package stockruntime

import (
	"context"
	"go/ast"
	"go/parser"
	"go/token"
	"net/http"
	"os"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// TestR4NilCollaboratorBranchesAreDefects enforces R4_FAILURE_STATUS_AMENDMENT
// item 7: a nil service, port or view is a composition defect (500 + 35028).
func TestR4NilCollaboratorBranchesAreDefects(t *testing.T) {
	entries, err := os.ReadDir(".")
	if err != nil {
		t.Fatal(err)
	}
	files := token.NewFileSet()
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, "_dispatcher.go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		file, err := parser.ParseFile(files, name, nil, 0)
		if err != nil {
			t.Fatalf("%s: %v", name, err)
		}
		ast.Inspect(file, func(node ast.Node) bool {
			branch, ok := node.(*ast.IfStmt)
			if !ok || !comparesSelectorToNil(branch.Cond) || !returnsUnavailableEvidence(branch.Body) {
				return true
			}
			t.Errorf("%s: nil collaborator branch returns an unavailable reply; R4_FAILURE_STATUS_AMENDMENT item 7 requires failureReply(defect(nil))", files.Position(branch.Pos()))
			return true
		})
	}
}

func TestR4NilCollaboratorsAnswerDefect(t *testing.T) {
	authority := httpAuthority{actorForHTTP(t)}
	now := time.Unix(100, 0).UTC()
	request := env(0, nil, now)
	socialDismissalRequest := env(184, nil, now)
	socialDismissalRequest.Envelope.Params["notice_ids"] = []any{int64(1)}
	practiceAutoParams := map[string]any{
		"partner_id":    int64(1),
		"locks":         []any{int64(1), int64(1), int64(1)},
		"practice_type": int64(1),
		"practice_num":  int64(2),
		"save_types":    []any{int64(1), int64(1), int64(1), int64(1)},
	}
	cases := []struct {
		name     string
		dispatch func() httpedge.Response
	}{
		{"achievement", func() httpedge.Response {
			return AchievementDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"adventure", func() httpedge.Response {
			return AdventureDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"arena", func() httpedge.Response {
			return ArenaDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"book", func() httpedge.Response {
			return BookDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"campaign", func() httpedge.Response {
			return CampaignDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"charge", func() httpedge.Response {
			return ChargeDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"conquer", func() httpedge.Response {
			return ConquerDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"course", func() httpedge.Response {
			return CourseDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"dorm", func() httpedge.Response {
			return DormDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"element", func() httpedge.Response {
			return ElementDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"event centre", func() httpedge.Response {
			return EventCentreDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"evolution", func() httpedge.Response {
			return EvolutionDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"friend fight", func() httpedge.Response {
			return FriendFightDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"gods trial", func() httpedge.Response {
			return GodsTrialDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"guild", func() httpedge.Response {
			return GuildDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"guild rental", func() httpedge.Response {
			return GuildRentalDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"guild tea", func() httpedge.Response {
			return GuildTeaDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"i5", func() httpedge.Response {
			return I5Dispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"i5 awakening", func() httpedge.Response {
			return I5Dispatcher{Authority: authority, Service: &i5WireFake{}}.Dispatch(context.Background(), env(163, nil, now))
		}},
		{"i5 missions", func() httpedge.Response {
			return I5Dispatcher{Authority: authority, Service: &i5WireFake{}}.Dispatch(context.Background(), env(171, nil, now))
		}},
		{"i5 sign in", func() httpedge.Response {
			return I5Dispatcher{Authority: authority, Service: &i5WireFake{}}.Dispatch(context.Background(), env(352, nil, now))
		}},
		{"illusion", func() httpedge.Response {
			return IllusionDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"illusion room", func() httpedge.Response {
			return IllusionRoomDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"inscription", func() httpedge.Response {
			return InscriptionDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"league", func() httpedge.Response {
			return LeagueDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"library", func() httpedge.Response {
			return LibraryDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"library forum", func() httpedge.Response {
			return LibraryForumDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"march", func() httpedge.Response {
			return MarchDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"memoir", func() httpedge.Response {
			return MemoirDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"occult", func() httpedge.Response {
			return OccultDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"one on one", func() httpedge.Response {
			return OneOnOneDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"pet", func() httpedge.Response {
			return PetDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"pet campaign", func() httpedge.Response {
			return PetCampaignDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"pet economy projection", func() httpedge.Response {
			cleanRequest := env(782, nil, now)
			cleanRequest.Envelope.Params["pet_id"] = int64(1)
			return PetDispatcher{Authority: authority, Service: &petServiceFake{}}.Dispatch(context.Background(), cleanRequest)
		}},
		{"practice auto", func() httpedge.Response {
			return PracticeDispatcher{}.dispatchPracticeAuto(context.Background(), httpedge.DispatchRequest{Envelope: part3bEnvelope(127, practiceAutoParams, now)}, actorForHTTP(t))
		}},
		{"social projection", func() httpedge.Response {
			return SocialDispatcher{Authority: authority}.Dispatch(context.Background(), env(176, nil, now))
		}},
		{"social dismissal", func() httpedge.Response {
			return SocialDispatcher{Authority: authority}.Dispatch(context.Background(), socialDismissalRequest)
		}},
		{"social relations", func() httpedge.Response {
			return SocialDispatcher{Authority: authority}.Dispatch(context.Background(), env(177, nil, now))
		}},
		{"spirit", func() httpedge.Response {
			return SpiritDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"summon", func() httpedge.Response {
			return SummonDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"top floor", func() httpedge.Response {
			return TopFloorDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"top floor task", func() httpedge.Response {
			return TopFloorTaskDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"tournament", func() httpedge.Response {
			return TournamentDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"workplace", func() httpedge.Response {
			return WorkplaceDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
		{"world boss", func() httpedge.Response {
			return WorldBossDispatcher{Authority: authority}.Dispatch(context.Background(), request)
		}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := tc.dispatch()
			if got.HTTPStatus != http.StatusInternalServerError || got.Body["error_code"] != unprovenRefusalCode || got.Body["error_msg"] != "" {
				t.Fatalf("status=%d body=%#v want 500/%d", got.HTTPStatus, got.Body, unprovenRefusalCode)
			}
		})
	}
}

func comparesSelectorToNil(condition ast.Expr) bool {
	found := false
	ast.Inspect(condition, func(node ast.Node) bool {
		comparison, ok := node.(*ast.BinaryExpr)
		if !ok || comparison.Op != token.EQL {
			return true
		}
		if isNilIdentifier(comparison.Y) && isSelectorExpression(comparison.X) || isNilIdentifier(comparison.X) && isSelectorExpression(comparison.Y) {
			found = true
		}
		return true
	})
	return found
}

func isNilIdentifier(expression ast.Expr) bool {
	identifier, ok := expression.(*ast.Ident)
	return ok && identifier.Name == "nil"
}

func isSelectorExpression(expression ast.Expr) bool {
	if parenthesized, ok := expression.(*ast.ParenExpr); ok {
		return isSelectorExpression(parenthesized.X)
	}
	_, ok := expression.(*ast.SelectorExpr)
	return ok
}

func returnsUnavailableEvidence(body *ast.BlockStmt) bool {
	found := false
	ast.Inspect(body, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.FuncLit:
			return false
		case *ast.ReturnStmt:
			for _, result := range typed.Results {
				if referencesUnavailable(result) {
					found = true
				}
			}
		}
		return true
	})
	return found
}

func referencesUnavailable(expression ast.Expr) bool {
	found := false
	ast.Inspect(expression, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.Ident:
			if typed.Name == "ErrUnavailable" {
				found = true
			}
		case *ast.CallExpr:
			if identifier, ok := typed.Fun.(*ast.Ident); ok && identifier.Name == "unavailable" {
				found = true
			}
		}
		return true
	})
	return found
}
