package main

import (
	"go/ast"
	"go/parser"
	"go/types"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func fixturePackage(t *testing.T, source string) (*typedWorld, *tracePackage) {
	t.Helper()
	world := newTypedWorld(t.TempDir())
	file, err := parser.ParseFile(world.fset, "fixture.go", source, 0)
	if err != nil {
		t.Fatal(err)
	}
	info := newTypeInfo()
	configuration := types.Config{}
	_, err = configuration.Check(modulePath+"internal/application/fixture", world.fset, []*ast.File{file}, info)
	if err != nil {
		t.Fatal(err)
	}
	pkg := &tracePackage{info: info, files: []*ast.File{file}, decls: map[string]*ast.FuncDecl{}, declFile: map[*ast.FuncDecl]*ast.File{}}
	for _, declaration := range file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok {
			continue
		}
		definition := info.Defs[function.Name].(*types.Func)
		pkg.decls[functionKey(definition)] = function
		pkg.declFile[function] = file
	}
	return world, pkg
}

func TestTraceSQLRejectsProse(t *testing.T) {
	read, write, locks := traceSQLTables("one unit from a lender per day")
	if len(read)+len(write)+len(locks) != 0 {
		t.Fatalf("prose became SQL: %v %v %v", read, write, locks)
	}
}

func TestStoreLocksUseReferencingFunction(t *testing.T) {
	source := `package fixture
 func Previous() {}
 const lockSQL = "SELECT owner_fence FROM realtime_presence_owner_state FOR SHARE"
 func AssertOwnerFenceTx() string { return lockSQL }
 `
	world, pkg := fixturePackage(t, source)
	store := "internal/adapters/postgres/presencestore"
	directory := filepath.Join(world.root, store)
	if err := os.MkdirAll(directory, 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(directory, "store.go"), []byte(source), 0644); err != nil {
		t.Fatal(err)
	}
	path := modulePath + store
	world.packages[path] = &listedPackage{ImportPath: path, Dir: directory, GoFiles: []string{"store.go"}}
	world.source = &sourceImporter{world: world, packages: map[string]*checkedPackage{path: {info: pkg.info, files: pkg.files}}, loading: map[string]bool{}}
	locks := world.rowLocks()
	if len(locks) != 1 || locks[0].Method != "AssertOwnerFenceTx" || locks[0].Table != "realtime_presence_owner_state" {
		t.Fatalf("wrong method attribution: %+v", locks)
	}
}

func TestTraceSelectsMIDIfAndStopsAtReturn(t *testing.T) {
	world, pkg := fixturePackage(t, `package fixture
 type Request struct { MID int }
 type Service struct{}
 func (Service) Load() {}
 func (Service) Claim() {}
 type Dispatcher struct { Service Service }
 func (d Dispatcher) Dispatch(r Request) {
  if r.MID == 1303 { d.Service.Claim(); return }
  d.Service.Load()
 }
 `)
	for _, test := range []struct {
		mid              int
		wanted, excluded string
	}{{1303, "Service.Claim ", "Service.Load "}, {1302, "Service.Load ", "Service.Claim "}} {
		walker := newTracer(world, test.mid)
		path := modulePath + "internal/application/fixture"
		walker.pkgs[path] = pkg
		walker.walk(traceTarget{pkgPath: path, receiver: "Dispatcher", name: "Dispatch"}, 0, true)
		result := strings.Join(walker.lines, "\n")
		if !strings.Contains(result, test.wanted) || strings.Contains(result, test.excluded) {
			t.Fatalf("MID%d wrong branch:\n%s", test.mid, result)
		}
	}
}

func TestTraceSQLReadsJoinedTablesWithoutCTEAliases(t *testing.T) {
	read, write, _ := traceSQLTables(`-- name: InsertReceipt :one
 WITH ins AS (INSERT INTO receipts(id) VALUES(1) RETURNING id), facts AS (SELECT id FROM ins)
 SELECT r.id FROM facts JOIN receipts r ON r.id=facts.id LEFT JOIN public.players p ON p.id=r.id`)
	if strings.Join(read, ",") != "players,receipts" || strings.Join(write, ",") != "receipts" {
		t.Fatalf("CTE/joins: %v %v", read, write)
	}
	read, _, _ = traceSQLTables(`WITH receipts AS (SELECT 1) SELECT id FROM public.receipts`)
	if strings.Join(read, ",") != "receipts" {
		t.Fatalf("qualified physical table lost: %v", read)
	}
}

func TestTypeCheckFailureDoesNotPublishPartialPackage(t *testing.T) {
	world := newTypedWorld(t.TempDir())
	path := modulePath + "internal/application/broken"
	filename := filepath.Join(world.root, "broken.go")
	if err := os.WriteFile(filename, []byte("package broken; var value int = missing"), 0644); err != nil {
		t.Fatal(err)
	}
	listed := &listedPackage{ImportPath: path, Dir: world.root, GoFiles: []string{"broken.go"}}
	world.packages[path] = listed
	world.source = &sourceImporter{world: world, packages: map[string]*checkedPackage{}, loading: map[string]bool{}}
	info, _ := world.check(listed)
	if info != nil {
		t.Fatal("partial type-check result presented as successful analysis")
	}
}

func TestSQLConstantConcatenationKeepsRelationAndLateLock(t *testing.T) {
	_, pkg := fixturePackage(t, `package fixture
 const columns = "json_build_object('id',id)"
 func ReadFight(lock bool) string {
  query := "SELECT " + columns + "::text FROM fights WHERE id=$1"
  if lock { query += " FOR UPDATE" }
  return query
 }
 `)
	for _, decl := range pkg.decls {
		read, _, locks := traceSQLTables(functionSQLText(decl, pkg.info))
		if strings.Join(read, ",") != "fights" || strings.Join(locks, ",") != "fights FOR UPDATE" {
			t.Fatalf("concatenated query lost: %v %v", read, locks)
		}
	}
}
