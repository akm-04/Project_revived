package archguard

import (
	"encoding/json"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// C1-3a: a MID declared read-only must reach only tx.RepeatableRead, ReadOnly
// transactions. The list is the migration review point: C1-3b adds a MID only
// together with its isolation change.

type readOnlyMID struct {
	MID      int    `json:"mid"`
	Function string `json:"function"`
	File     string `json:"file"`
	// FileOnly marks a read-only MID that reaches no transaction at all, such
	// as MID 2 reading releases.json (S1 item 2). It must not open one.
	FileOnly bool `json:"file_only,omitempty"`
}

type readOnlyMIDsFile struct {
	MIDs []readOnlyMID `json:"mids"`
}

// midClassesFile is the part of the generated system map the read-only ledger
// is proved complete against. A MID is read-only when the map traces at least
// one transaction and every traced transaction is read_only true.
type midClassesFile struct {
	MIDs []struct {
		MID          int `json:"mid"`
		Transactions []struct {
			Function string `json:"function"`
			File     string `json:"file"`
			ReadOnly string `json:"read_only"`
		} `json:"transactions"`
	} `json:"mids"`
}

func loadReadOnlyMIDs(t *testing.T, root string) readOnlyMIDsFile {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join(root, "internal", "archguard", "read_only_mids.json"))
	if err != nil {
		t.Fatal(err)
	}
	var listed readOnlyMIDsFile
	if err := json.Unmarshal(raw, &listed); err != nil {
		t.Fatal(err)
	}
	return listed
}

// readOnlyMIDKey drops the ledger-only file_only annotation, so the coverage
// comparison uses the route identity the system map traces.
func readOnlyMIDKey(entry readOnlyMID) readOnlyMID {
	entry.FileOnly = false
	return entry
}

func loadMIDClasses(t *testing.T, root string) midClassesFile {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join(root, "docs", "architecture", "system_map", "MID_CLASSES.json"))
	if err != nil {
		t.Fatal(err)
	}
	var classes midClassesFile
	if err := json.Unmarshal(raw, &classes); err != nil {
		t.Fatal(err)
	}
	if len(classes.MIDs) == 0 {
		t.Fatal("MID_CLASSES.json has no rows")
	}
	return classes
}

// TestC1ReadOnlyMIDLedgerCoversLiveReadOnlyMIDs derives the required ledger
// population from the generated system map instead of trusting the hand list.
// A ledger entry whose MID has no traced transaction stays admissible: the map
// cannot see that route's transactions, so the ledger is the only evidence.
func TestC1ReadOnlyMIDLedgerCoversLiveReadOnlyMIDs(t *testing.T) {
	root := repoRoot(t)
	ledger := loadReadOnlyMIDs(t, root)
	classes := loadMIDClasses(t, root)
	live := map[readOnlyMID]bool{}
	mapBlindMIDs := map[int]bool{}
	for _, row := range classes.MIDs {
		if len(row.Transactions) == 0 {
			mapBlindMIDs[row.MID] = true
			continue
		}
		readOnly := true
		for _, transaction := range row.Transactions {
			if strings.ToLower(transaction.ReadOnly) != "true" {
				readOnly = false
			}
		}
		if !readOnly {
			continue
		}
		for _, transaction := range row.Transactions {
			live[readOnlyMID{MID: row.MID, Function: transaction.Function, File: transaction.File}] = true
		}
	}
	listed := map[readOnlyMID]bool{}
	for _, entry := range ledger.MIDs {
		key := readOnlyMIDKey(entry)
		listed[key] = true
		if !live[key] && !mapBlindMIDs[entry.MID] {
			t.Errorf("MID %d: ledger names %s %s, but the system map traces no read-only-only route for it", entry.MID, entry.File, entry.Function)
		}
	}
	for entry := range live {
		if !listed[entry] {

			t.Errorf("MID %d: live read-only route %s %s is missing from internal/archguard/read_only_mids.json", entry.MID, entry.File, entry.Function)
		}
	}
}

func TestC1ReadOnlyMIDsStayRepeatableReadOnly(t *testing.T) {
	root := repoRoot(t)
	listed := loadReadOnlyMIDs(t, root)
	files := map[string][]byte{}
	for _, entry := range listed.MIDs {
		if _, ok := files[entry.File]; ok {
			continue
		}
		content, err := os.ReadFile(filepath.Join(root, entry.File))
		if err != nil {
			t.Fatalf("MID %d names %s: %v", entry.MID, entry.File, err)
		}
		files[entry.File] = content
	}
	for _, problem := range readOnlyMIDProblems(files, listed.MIDs) {
		t.Error(problem)
	}
}

func TestC1ReadOnlyMIDGuardRejectsSerializerAndWriter(t *testing.T) {
	source := `package fixture
func (m Mode) Load(c context.Context) error {
	return m.Runner.Run(c, op, profile, tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, body)
}
func (m Mode) Save(c context.Context) error {
	return m.Runner.Run(c, op, profile, tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, body)
}
`
	entries := []readOnlyMID{
		{MID: 1, Function: "Mode.Load", File: "fixture.go"},
		{MID: 2, Function: "Mode.Save", File: "fixture.go"},
	}
	problems := readOnlyMIDProblems(map[string][]byte{"fixture.go": []byte(source)}, entries)
	if len(problems) != 2 {
		t.Fatalf("problems = %v, want one per offending MID", problems)
	}
	if !strings.Contains(problems[0], "MID 1") || !strings.Contains(problems[0], "Serializable") {
		t.Fatalf("serializable MID was not named: %v", problems)
	}
	if !strings.Contains(problems[1], "MID 2") || !strings.Contains(problems[1], "ReadOnly") {
		t.Fatalf("writable MID was not named: %v", problems)
	}
}

func TestC1ReadOnlyMIDGuardAcceptsRepeatableReadOnly(t *testing.T) {
	source := `package fixture
func (m Mode) Load(c context.Context) error {
	return m.Runner.Run(c, op, profile, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, body)
}
`
	problems := readOnlyMIDProblems(
		map[string][]byte{"fixture.go": []byte(source)},
		[]readOnlyMID{{MID: 1, Function: "Mode.Load", File: "fixture.go"}},
	)
	if len(problems) != 0 {
		t.Fatalf("repeatable-read read-only was rejected: %v", problems)
	}
}

func TestC1ReadOnlyMIDGuardAcceptsFileOnlyRoute(t *testing.T) {
	source := `package fixture
func (s Service) activeRows(c context.Context) error {
	return nil
}
`
	problems := readOnlyMIDProblems(
		map[string][]byte{"fixture.go": []byte(source)},
		[]readOnlyMID{{MID: 2, Function: "Service.activeRows", File: "fixture.go", FileOnly: true}},
	)
	if len(problems) != 0 {
		t.Fatalf("a file-only read-only route was rejected: %v", problems)
	}
}

func TestC1ReadOnlyMIDGuardRejectsFileOnlyRouteThatOpensATransaction(t *testing.T) {
	source := `package fixture
func (s Service) activeRows(c context.Context) error {
	return s.Runner.Run(c, op, profile, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, body)
}
`
	problems := readOnlyMIDProblems(
		map[string][]byte{"fixture.go": []byte(source)},
		[]readOnlyMID{{MID: 2, Function: "Service.activeRows", File: "fixture.go", FileOnly: true}},
	)
	if len(problems) != 1 || !strings.Contains(problems[0], "file_only") {
		t.Fatalf("a file-only route that opened a transaction was not rejected: %v", problems)
	}
}

// readOnlyMIDProblems is pure so the guard can be tested with synthetic source.
func readOnlyMIDProblems(files map[string][]byte, entries []readOnlyMID) []string {
	problems := []string{}
	for _, entry := range entries {
		content, ok := files[entry.File]
		if !ok {
			problems = append(problems, fmt.Sprintf("MID %d: %s not read", entry.MID, entry.File))
			continue
		}
		position := token.NewFileSet()
		file, err := parser.ParseFile(position, entry.File, content, 0)
		if err != nil {
			problems = append(problems, fmt.Sprintf("MID %d: %s: %v", entry.MID, entry.File, err))
			continue
		}
		function := findFunction(file, entry.Function)
		if function == nil {
			problems = append(problems, fmt.Sprintf("MID %d: %s does not define %s", entry.MID, entry.File, entry.Function))
			continue
		}
		found, failures := checkTransactionOptions(position, entry, function)
		if entry.FileOnly {
			if found {
				problems = append(problems, fmt.Sprintf("MID %d: %s opens a transaction, but the ledger marks it file_only", entry.MID, entry.File))
			}
			continue
		}
		if !found {
			problems = append(problems, fmt.Sprintf("MID %d: %s has no Runner.Run with tx.Options", entry.MID, entry.File))
			continue
		}
		problems = append(problems, failures...)
	}
	return problems
}

func findFunction(file *ast.File, name string) *ast.FuncDecl {
	for _, declaration := range file.Decls {
		function, ok := declaration.(*ast.FuncDecl)
		if !ok || function.Body == nil {
			continue
		}
		qualified := function.Name.Name
		if function.Recv != nil && len(function.Recv.List) > 0 {
			qualified = expressionName(function.Recv.List[0].Type) + "." + function.Name.Name
		}
		if qualified == name {
			return function
		}
	}
	return nil
}

func expressionName(expression ast.Expr) string {
	switch typed := expression.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.StarExpr:
		return expressionName(typed.X)
	case *ast.SelectorExpr:
		return typed.Sel.Name
	}
	return ""
}

func checkTransactionOptions(position *token.FileSet, entry readOnlyMID, function *ast.FuncDecl) (bool, []string) {
	found := false
	failures := []string{}
	ast.Inspect(function.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok || selector.Sel.Name != "Run" {
			return true
		}
		options := optionsLiteral(call)
		if options == nil {
			return true
		}
		found = true
		isolation, readOnly := optionValues(options)
		if isolation != "RepeatableRead" || !readOnly {
			where := position.Position(options.Pos())
			failures = append(failures, fmt.Sprintf(
				"MID %d: %s:%d reaches tx.Options{Isolation: %s, ReadOnly: %t}, want tx.RepeatableRead with ReadOnly true",
				entry.MID, entry.File, where.Line, isolation, readOnly))
		}
		return true
	})
	return found, failures
}

func optionsLiteral(call *ast.CallExpr) *ast.CompositeLit {
	for _, argument := range call.Args {
		literal, ok := argument.(*ast.CompositeLit)
		if !ok {
			continue
		}
		if expressionName(literal.Type) == "Options" {
			return literal
		}
	}
	return nil
}

func optionValues(options *ast.CompositeLit) (string, bool) {
	isolation := ""
	readOnly := false
	for _, element := range options.Elts {
		pair, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := pair.Key.(*ast.Ident)
		if !ok {
			continue
		}
		switch key.Name {
		case "Isolation":
			isolation = expressionName(pair.Value)
		case "ReadOnly":
			identifier, ok := pair.Value.(*ast.Ident)
			readOnly = ok && identifier.Name == "true"
		}
	}
	return isolation, readOnly
}
