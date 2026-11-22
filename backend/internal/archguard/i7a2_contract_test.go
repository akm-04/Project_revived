package archguard

import (
	"fmt"
	"go/ast"
	"go/format"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
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
	"realtimewakeup.Registration{Route: guildcore.ApplyNoticeRoute, Handler: guildApplyNotices}",
	"realtimewakeup.Registration{Route: appbroadcast.Route, Handler: broadcastNotices}",
	"realtimewakeup.Registration{Route: applibrary.PartnerLogNoticeRoute, Handler: libraryPartnerLogNotices}",
	"realtimewakeup.Registration{Route: applibrary.MissionNoticeRoute, Handler: libraryMissionNotices}",
}

// allowedRegistrations is the identity allow-list for I7A-2 notice and direct
// producers. Its population is every NoticeRegistration/DirectRegistration
// literal in the product tree, collected by collectRegistrationIdentities, so a
// second registration in an allowed file is unlisted and fails.
type registrationActivation int

const (
	dormantRegistration registrationActivation = iota
	generalDMRegistration
	friendDMRegistration
	socialRegistration
)

type allowedRegistration struct {
	activation registrationActivation
	count      int
}

var allowedRegistrations = map[string]allowedRegistration{
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:AchievementNoticeType,Validate:ValidateAchievementNotice}":             {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:app.NoticeFinish,Validate:ValidateAdventureFinishNotice}":              {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:app.NoticeOccur,Validate:ValidateAdventureOccurNotice}":                {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:AdventureRoomNoticeType,Validate:ValidateAdventureRoomNotice}":         {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:14,Validate:ValidateFriendFightNotice}":                                {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:15,Validate:ValidateFriendFightNotice}":                                {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:GuildApplyNoticeType,Validate:ValidateGuildApplyNotice}":               {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:OccultRoomNoticeType,Validate:ValidateOccultRoomNotice}":               {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:LibraryPartnerLogNoticeType,Validate:ValidateLibraryPartnerLogNotice}": {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:LibraryMissionNoticeType,Validate:ValidateLibraryMissionNotice}":       {dormantRegistration, 1},
	"rt.NoticeRegistration{ParentMID:mids.MIDPlayerNotice,Namespace:rt.NoticeNamespaceGeneric,NoticeType:TournamentNoticeType,Validate:ValidateTournamentNotice}":               {dormantRegistration, 1},
	"rt.DirectRegistration{MID:mids.MIDActivityBroadcast,Validate:ValidateActivityBroadcast}":                                                                                   {dormantRegistration, 1},
	"rt.DirectRegistration{MID:mids.MIDSystemBroadcast,Validate:ValidateSystemBroadcast}":                                                                                       {dormantRegistration, 1},
	"rt.DirectRegistration{MID:mids.MIDGuildFightNotice,Validate:ValidateGuildFightNotice}":                                                                                     {dormantRegistration, 1},
	"rt.DirectRegistration{MID:mids.MIDIllusionNotice,Validate:ValidateIllusionRoomNotice}":                                                                                     {dormantRegistration, 1},
	"DirectRegistration{MID:mids.MIDChatMessage,Validate:ValidateChannelChat}":                                                                                                  {dormantRegistration, 1},
	"rt.DirectRegistration{MID:mids.MIDChatFromPlayer,Validate:rt.ValidateGeneralDM}":                                                                                           {generalDMRegistration, 1},
	"rt.DirectRegistration{MID:mids.MIDChatFromFriend,Validate:rt.ValidateFriendDM}":                                                                                            {friendDMRegistration, 5},
	"rt.DirectRegistration{MID:mids.MIDForceReload,Validate:ValidateSocialReload}":                                                                                              {socialRegistration, 3},
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
		// routes activate in later owning stages with their exact recovery and
		// schema contracts; registrations are checked by identity below.
		for _, marker := range []string{
			"realtimewakeup.Registration{",
			"appwakeup.Registration{",
		} {
			if !strings.Contains(s, marker) {
				continue
			}
			rel, _ := filepath.Rel(root, path)
			if marker == "realtimewakeup.Registration{" {
				for _, route := range familyNoticeRoutes {
					s = strings.Replace(s, route, "", 1)
				}
				s = strings.Replace(s, achievementNoticeRoute, "", 1)
				s = strings.Replace(s, tournamentNoticeRoute, "", 1)
				s = strings.Replace(s, friendFightNoticeRoute, "", 1)
			}
			allowedFriendRoutes := filepath.ToSlash(rel) == "cmd/gxb-realtime/main_postgres.go" && marker == "realtimewakeup.Registration{" && (strings.Count(s, marker) == 2 || strings.Count(s, marker) == 3 && selectedGeneralDMActivation(t)) && strings.Contains(s, "Route: frienddm.WakeupRoute, Handler: friendReconcile")
			if allowedFriendRoutes && selectedFriendDMActivation(t) {
				validateSocialActivationRoutes(t)
				validateFriendDMActivation(t)
				continue
			}
			allowedSocial := filepath.ToSlash(rel) == "cmd/gxb-realtime/main_postgres.go" && marker == "realtimewakeup.Registration{" && strings.Count(s, marker) == 1 && strings.Contains(s, "Route: postgres.SocialReloadRoute, Handler: socialHandler")
			if allowedSocial && selectedSocialActivation(t) {
				validateSocialActivationRoutes(t)
				continue
			}
			offenders = append(offenders, filepath.ToSlash(rel)+": "+marker)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	for identity, files := range collectRegistrationIdentities(t, root) {
		allowed, listed := allowedRegistrations[identity]
		if !listed {
			offenders = append(offenders, strings.Join(files, ",")+": unlisted registration "+identity)
			continue
		}
		if len(files) != allowed.count {
			offenders = append(offenders, strings.Join(files, ",")+fmt.Sprintf(": registration count %d, want %d: %s", len(files), allowed.count, identity))
			continue
		}
		switch allowed.activation {
		case generalDMRegistration:
			if !selectedGeneralDMActivation(t) {
				offenders = append(offenders, strings.Join(files, ",")+": selected registration is not activated "+identity)
				continue
			}
			validateGeneralDMActivation(t)
		case friendDMRegistration:
			if !selectedFriendDMActivation(t) {
				offenders = append(offenders, strings.Join(files, ",")+": selected registration is not activated "+identity)
				continue
			}
			validateSocialActivationRoutes(t)
			validateFriendDMActivation(t)
		case socialRegistration:
			if !selectedSocialActivation(t) {
				offenders = append(offenders, strings.Join(files, ",")+": selected registration is not activated "+identity)
				continue
			}
			validateSocialActivationRoutes(t)
		}
	}
	if len(offenders) != 0 {
		sort.Strings(offenders)
		t.Fatalf("I7A-2 unexpectedly activates a deferred producer/route: %v", offenders)
	}
}

func collectRegistrationIdentities(t *testing.T, root string) map[string][]string {
	t.Helper()
	identities := map[string][]string{}
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
		raw, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		text := string(raw)
		if !strings.Contains(text, "NoticeRegistration") && !strings.Contains(text, "DirectRegistration") {
			return nil
		}
		parsed, err := parser.ParseFile(token.NewFileSet(), path, raw, 0)
		if err != nil {
			return err
		}
		relative, _ := filepath.Rel(root, path)
		for _, identity := range fileRegistrationIdentities(parsed) {
			identities[identity] = append(identities[identity], filepath.ToSlash(relative))
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	return identities
}

func fileRegistrationIdentities(file *ast.File) []string {
	identities := []string{}
	ast.Inspect(file, func(node ast.Node) bool {
		literal, ok := node.(*ast.CompositeLit)
		if !ok {
			return true
		}
		if array, ok := literal.Type.(*ast.ArrayType); ok {
			typeName := registrationTypeName(array.Elt)
			if !isRegistrationType(typeName) {
				return true
			}
			for _, element := range literal.Elts {
				inner, ok := element.(*ast.CompositeLit)
				if !ok || inner.Type != nil {
					continue
				}
				identities = append(identities, registrationIdentity(typeName, inner))
			}
			return true
		}
		typeName := registrationTypeName(literal.Type)
		if isRegistrationType(typeName) {
			identities = append(identities, registrationIdentity(typeName, literal))
		}
		return true
	})
	return identities
}

func registrationTypeName(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.SelectorExpr:
		return expressionName(typed.X) + "." + typed.Sel.Name
	case *ast.Ident:
		return typed.Name
	}
	return ""
}

func isRegistrationType(name string) bool {
	return strings.HasSuffix(name, "NoticeRegistration") || strings.HasSuffix(name, "DirectRegistration")
}

// registrationIdentity names one registration by its distinguishing fields, so
// the allow-list below accepts registrations, not files.
func registrationIdentity(typeName string, literal *ast.CompositeLit) string {
	fields := []string{}
	for _, wanted := range []string{"MID", "ParentMID", "Namespace", "NoticeType", "Validate"} {
		for _, element := range literal.Elts {
			pair, ok := element.(*ast.KeyValueExpr)
			if !ok {
				continue
			}
			key, ok := pair.Key.(*ast.Ident)
			if !ok || key.Name != wanted {
				continue
			}
			fields = append(fields, wanted+":"+renderExpression(pair.Value))
		}
	}
	return typeName + "{" + strings.Join(fields, ",") + "}"
}

func renderExpression(expression ast.Expr) string {
	var rendered strings.Builder
	if err := format.Node(&rendered, token.NewFileSet(), expression); err != nil {
		return ""
	}
	return rendered.String()
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
