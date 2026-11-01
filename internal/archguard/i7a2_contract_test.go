package archguard

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func TestI7A2SessionHandleDoesNotExposeRawConnectionState(t *testing.T) {
	root := repoRoot(t)
	path := filepath.Join(root, "internal", "adapters", "stockruntime", "realtime_registry.go")
	f, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, decl := range f.Decls {
		gd, ok := decl.(*ast.GenDecl)
		if !ok || gd.Tok != token.TYPE {
			continue
		}
		for _, spec := range gd.Specs {
			ts, ok := spec.(*ast.TypeSpec)
			if !ok || ts.Name.Name != "SessionHandle" {
				continue
			}
			found = true
			st, ok := ts.Type.(*ast.StructType)
			if !ok {
				t.Fatal("SessionHandle is no longer a struct")
			}
			for _, field := range st.Fields.List {
				for _, name := range field.Names {
					if ast.IsExported(name.Name) {
						t.Fatalf("SessionHandle exposes field %q; feature callers must receive immutable capability only", name.Name)
					}
				}
			}
		}
	}
	if !found {
		t.Fatal("SessionHandle type not found")
	}
}

func TestI7A2OnlyCanonicalWriterTouchesConnWrite(t *testing.T) {
	root := repoRoot(t)
	base := filepath.Join(root, "internal", "adapters", "stockruntime")
	var offenders []string
	err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if strings.Contains(string(b), "conn.Write(") && filepath.Base(path) != "realtime_writer.go" {
			rel, _ := filepath.Rel(root, path)
			offenders = append(offenders, filepath.ToSlash(rel))
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(offenders) != 0 {
		t.Fatalf("non-canonical realtime writers found: %v", offenders)
	}
}

func TestI7A2ApplicationSeamsRemainProtocolAndPersistenceFree(t *testing.T) {
	root := repoRoot(t)
	for _, pkg := range []string{"playerpresentation", "realtimewakeup"} {
		base := filepath.Join(root, "internal", "application", pkg)
		err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() || !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
				return nil
			}
			f, err := parser.ParseFile(token.NewFileSet(), path, nil, parser.ImportsOnly)
			if err != nil {
				return err
			}
			for _, im := range f.Imports {
				imp, _ := strconv.Unquote(im.Path.Value)
				if strings.Contains(imp, "/internal/protocol/") || strings.Contains(imp, "/internal/adapters/") || strings.HasPrefix(imp, "github.com/jackc/pgx") || strings.HasPrefix(imp, "github.com/riverqueue/") {
					rel, _ := filepath.Rel(root, path)
					t.Errorf("%s imports edge/persistence dependency %q", filepath.ToSlash(rel), imp)
				}
			}
			b, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			upper := strings.ToUpper(string(b))
			for _, marker := range []string{"SELECT ", "INSERT ", "UPDATE ", "DELETE ", "PG_NOTIFY("} {
				if strings.Contains(upper, marker) {
					rel, _ := filepath.Rel(root, path)
					t.Errorf("%s contains persistence marker %q", filepath.ToSlash(rel), marker)
				}
			}
			return nil
		})
		if err != nil {
			t.Fatal(err)
		}
	}
}

// achievementNoticeRoute is the one feature-specific route I7C-4 full stage A
// adds (C4F_ACHIEVEMENT_NOTICE_V1); it is not a generic bus or worker.
const achievementNoticeRoute = "realtimewakeup.Registration{Route: achievement.NoticeRoute, Handler: achievementNotices}"

const tournamentNoticeRoute = "realtimewakeup.Registration{Route: apparena.TournamentNoticeRoute, Handler: tournamentNotices}"

const friendFightNoticeRoute = "realtimewakeup.Registration{Route: apparena.FriendFightNoticeRoute, Handler: friendNotices}"

// The I9-8 family notice routes are feature-specific, each owned by its contract.
var familyNoticeRoutes = []string{
	"realtimewakeup.Registration{Route: appillusion.RoomNoticeRoute, Handler: illusionRooms}",
	"realtimewakeup.Registration{Route: appoccult.RoomNoticeRoute, Handler: occultRooms}",
	"realtimewakeup.Registration{Route: appadventure.NoticeRoute, Handler: adventureNotices}",
	"realtimewakeup.Registration{Route: appadventure.RoomNoticeRoute, Handler: adventureRooms}",
	"realtimewakeup.Registration{Route: roominvite.NoticeListRoute, Handler: roomInviteNotices}",
	"realtimewakeup.Registration{Route: stockruntime.GuildCampaignNoticeRoute, Handler: guildFightNotices}",
}

var familyNoticeSchemas = map[string]bool{
	"internal/adapters/stockruntime/illusion_room_notice.go":  true,
	"internal/adapters/stockruntime/occult_room_notice.go":    true,
	"internal/adapters/stockruntime/adventure_notice.go":      true,
	"internal/adapters/stockruntime/adventure_room_notice.go": true,
	"internal/adapters/stockruntime/guild_fight_notice.go":    true,
}

func genericWakeupRoutes(realtime string) int {
	generic := strings.Count(realtime, "realtimewakeup.Registration{") - strings.Count(realtime, achievementNoticeRoute) - strings.Count(realtime, tournamentNoticeRoute) - strings.Count(realtime, friendFightNoticeRoute)
	for _, route := range familyNoticeRoutes {
		generic -= strings.Count(realtime, route)
	}
	return generic
}

func TestI7A2KeepsFeatureProducerAndWakeupRoutesDormant(t *testing.T) {
	root := repoRoot(t)
	var offenders []string
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if outsideProduct(root, path, d) || strings.Contains(filepath.ToSlash(path), "/vendor/") {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
			return nil
		}
		b, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		s := string(b)
		// I7A-2 installs mechanisms and source descriptors only. Domain-owned
		// producers/routes activate in later owning stages with their exact
		// recovery and schema contracts.
		for _, marker := range []string{
			"realtime.DirectRegistration{",
			"realtime.NoticeRegistration{",
			"wireRT.DirectRegistration{",
			"rt.DirectRegistration{",
			"wireRT.NoticeRegistration{",
			"rt.NoticeRegistration{",
			"realtimewakeup.Registration{",
			"appwakeup.Registration{",
		} {
			if strings.Contains(s, marker) {
				rel, _ := filepath.Rel(root, path)
				// I7C-4 full stage A activates exactly one notice schema (17) and its route.
				achievementSchema := filepath.ToSlash(rel) == "internal/adapters/stockruntime/achievement_notice.go" && marker == "rt.NoticeRegistration{" && strings.Count(s, marker) == 1 && strings.Count(s, "NoticeType:") == 1
				tournamentSchema := filepath.ToSlash(rel) == "internal/adapters/stockruntime/tournament_notice.go" && marker == "rt.NoticeRegistration{" && strings.Count(s, marker) == 1 && strings.Count(s, "NoticeType:") == 1
				friendFightSchema := filepath.ToSlash(rel) == "internal/adapters/stockruntime/friend_fight_notice.go" && marker == "rt.NoticeRegistration{" && strings.Count(s, marker) == 1 && strings.Count(s, "NoticeType:") == 2
				familySchema := familyNoticeSchemas[filepath.ToSlash(rel)] && (marker == "rt.NoticeRegistration{" || marker == "rt.DirectRegistration{")
				if achievementSchema || tournamentSchema || friendFightSchema || familySchema {
					continue
				}
				if marker == "realtimewakeup.Registration{" {
					for _, route := range familyNoticeRoutes {
						s = strings.Replace(s, route, "", 1)
					}
					s = strings.Replace(s, achievementNoticeRoute, "", 1)
					s = strings.Replace(s, tournamentNoticeRoute, "", 1)
					s = strings.Replace(s, friendFightNoticeRoute, "", 1)
				}
				allowedGeneralSchema := filepath.ToSlash(rel) == "internal/adapters/stockruntime/general_dm_events.go" && marker == "rt.DirectRegistration{" && strings.Count(s, marker) == 1
				if allowedGeneralSchema && selectedGeneralDMActivation(t) {
					validateGeneralDMActivation(t)
					continue
				}
				allowedFriendSchema := filepath.ToSlash(rel) == "internal/adapters/stockruntime/friend_dm_delivery.go" && marker == "rt.DirectRegistration{" && strings.Count(s, marker) == 1
				allowedFriendRoutes := filepath.ToSlash(rel) == "cmd/gxb-realtime/main_postgres.go" && marker == "realtimewakeup.Registration{" && (strings.Count(s, marker) == 2 || strings.Count(s, marker) == 3 && selectedGeneralDMActivation(t)) && strings.Contains(s, "Route: frienddm.WakeupRoute, Handler: friendReconcile")
				if (allowedFriendSchema || allowedFriendRoutes) && selectedFriendDMActivation(t) {
					validateSocialActivationRoutes(t)
					validateFriendDMActivation(t)
					continue
				}
				allowedSocial := filepath.ToSlash(rel) == "cmd/gxb-realtime/main_postgres.go" && marker == "realtimewakeup.Registration{" && strings.Count(s, marker) == 1 && strings.Contains(s, "Route: postgres.SocialReloadRoute, Handler: socialHandler")
				allowedSchema := filepath.ToSlash(rel) == "internal/adapters/stockruntime/social_reload.go" && marker == "rt.DirectRegistration{" && strings.Count(s, marker) == 1 && strings.Count(s, "MID:") == 1
				if (allowedSocial || allowedSchema) && selectedSocialActivation(t) {
					validateSocialActivationRoutes(t)
					continue
				}
				offenders = append(offenders, filepath.ToSlash(rel)+": "+marker)
			}
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(offenders) != 0 {
		t.Fatalf("I7A-2 unexpectedly activates a deferred producer/route: %v", offenders)
	}
}

func TestI97BFiniteTournamentNoticeDoesNotAddGenericTransport(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join(repoRoot(t), "cmd/gxb-realtime/main_postgres.go"))
	if err != nil {
		t.Fatal(err)
	}
	text := string(raw)
	if strings.Count(text, tournamentNoticeRoute) != 1 || strings.Count(text, friendFightNoticeRoute) != 1 || genericWakeupRoutes(text) != 3 {
		t.Fatal("finite route or generic transport drift")
	}
	if genericWakeupRoutes(text+"realtimewakeup.Registration{Route: unexpected}") != 4 {
		t.Fatal("extra generic transport escaped guard")
	}
}
