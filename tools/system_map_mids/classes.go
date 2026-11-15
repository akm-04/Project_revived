package main

import (
	"go/ast"
	"go/constant"
	"go/types"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// C1-3a MID classes: what transaction a registered stock HTTP MID reaches.
// Values are static-trace facts. A marker (FANOUT, UNRESOLVED, BOUND) means the
// walk could not decide, so the field stays UNKNOWN rather than guessing.

const (
	txPackagePath         = modulePath + "internal/foundation/tx"
	generationPackagePath = modulePath + "internal/application/generation"
)

type classEvidence struct {
	Value string `json:"value"`
	File  string `json:"file"`
	Line  int    `json:"line"`
}

type classTransaction struct {
	Function  string `json:"function"`
	Isolation string `json:"isolation"`
	ReadOnly  string `json:"read_only"`
	Retry     string `json:"retry"`
	File      string `json:"file"`
	Line      int    `json:"line"`
}

type unboundedRead struct {
	Statement string `json:"statement"`
	File      string `json:"file"`
	Line      int    `json:"line"`
}

type midClass struct {
	MID            int                `json:"mid"`
	Handler        string             `json:"handler"`
	System         string             `json:"system,omitempty"`
	Isolation      []classEvidence    `json:"isolation"`
	ReadOnly       []classEvidence    `json:"read_only"`
	Retry          []classEvidence    `json:"retry"`
	Transactions   []classTransaction `json:"transactions"`
	Writes         string             `json:"writes"`
	ReceiptWrites  []string           `json:"receipt_writes"`
	StateWrites    []string           `json:"state_writes"`
	UnboundedReads []unboundedRead    `json:"unbounded_read"`
	Unknown        []string           `json:"unknown,omitempty"`
}

type classBuilder struct {
	runs        []classTransaction
	receipts    []string
	stateWrites []string
	unbounded   []unboundedRead
	markers     []string
}

func (b *classBuilder) noteMarker(reason string) {
	for _, existing := range b.markers {
		if existing == reason {
			return
		}
	}
	b.markers = append(b.markers, reason)
}

func (b *classBuilder) recordReceipt(site string) {
	for _, existing := range b.receipts {
		if existing == site {
			return
		}
	}
	b.receipts = append(b.receipts, site)
}

func (b *classBuilder) recordStateWrite(site string) {
	for _, existing := range b.stateWrites {
		if existing == site {
			return
		}
	}
	b.stateWrites = append(b.stateWrites, site)
}

func (b *classBuilder) recordUnbounded(read unboundedRead) {
	for _, existing := range b.unbounded {
		if existing.Statement == read.Statement && existing.File == read.File && existing.Line == read.Line {
			return
		}
	}
	b.unbounded = append(b.unbounded, read)
}

func (b *classBuilder) addRun(run classTransaction) {
	for _, existing := range b.runs {
		if existing == run {
			return
		}
	}
	b.runs = append(b.runs, run)
}

// writes class precedence: non-receipt state writes (the receipt row itself is
// excluded), else a recorded operation receipt, else none only when the walk
// raised no marker that could hide a write.
func (b *classBuilder) writes() string {
	if len(b.stateWrites) > 0 {
		return "state"
	}
	if len(b.receipts) > 0 {
		return "receipt"
	}
	if len(b.markers) > 0 {
		return "UNKNOWN"
	}
	return "none"
}

func (b *classBuilder) build(mid int, reg registration) midClass {
	class := midClass{
		MID: mid, Handler: reg.HandlerFile, Isolation: []classEvidence{}, ReadOnly: []classEvidence{},
		Retry: []classEvidence{}, Transactions: []classTransaction{}, ReceiptWrites: []string{}, StateWrites: []string{},
		UnboundedReads: []unboundedRead{}, Unknown: []string{},
	}
	if reg.Owner != "" {
		class.System = reg.Owner
	}
	for _, run := range b.runs {
		class.Transactions = append(class.Transactions, run)
		class.Isolation = append(class.Isolation, classEvidence{Value: run.Isolation, File: run.File, Line: run.Line})
		class.ReadOnly = append(class.ReadOnly, classEvidence{Value: run.ReadOnly, File: run.File, Line: run.Line})
		class.Retry = append(class.Retry, classEvidence{Value: run.Retry, File: run.File, Line: run.Line})
	}
	sort.Slice(class.Transactions, func(i, j int) bool {
		if class.Transactions[i].File != class.Transactions[j].File {
			return class.Transactions[i].File < class.Transactions[j].File
		}
		return class.Transactions[i].Line < class.Transactions[j].Line
	})
	sortClassEvidenceSites(class.Isolation)
	sortClassEvidenceSites(class.ReadOnly)
	sortClassEvidenceSites(class.Retry)
	class.ReceiptWrites = append(class.ReceiptWrites, b.receipts...)
	sort.Strings(class.ReceiptWrites)
	class.StateWrites = append(class.StateWrites, b.stateWrites...)
	sort.Strings(class.StateWrites)
	class.UnboundedReads = append(class.UnboundedReads, b.unbounded...)
	sort.Slice(class.UnboundedReads, func(i, j int) bool {
		if class.UnboundedReads[i].File != class.UnboundedReads[j].File {
			return class.UnboundedReads[i].File < class.UnboundedReads[j].File
		}
		if class.UnboundedReads[i].Line != class.UnboundedReads[j].Line {
			return class.UnboundedReads[i].Line < class.UnboundedReads[j].Line
		}
		return class.UnboundedReads[i].Statement < class.UnboundedReads[j].Statement
	})
	class.Unknown = append(class.Unknown, b.markers...)
	sort.Strings(class.Unknown)
	class.Writes = b.writes()
	return class
}

// collectMIDClasses walks every active registered route once and records the
// transaction it reaches. Inactive fallback registrations have no route to
// walk, so they are reported as undecided rather than as read-only.
func collectMIDClasses(out *output, w *typedWorld) []midClass {
	classes := []midClass{}
	active := map[int]bool{}
	for _, reg := range out.Registrations {
		if reg.Fallback || reg.DispatcherPackage == "" || reg.HandlerFile == "" || active[reg.MID] {
			continue
		}
		active[reg.MID] = true
		walker := newTracer(w, reg.MID)
		walker.class = &classBuilder{}
		walker.skipRunnerInternals = true
		walker.walk(traceTarget{pkgPath: reg.DispatcherPackage, receiver: reg.DispatcherType, name: "Dispatch"}, 0, true)
		classes = append(classes, walker.class.build(reg.MID, reg))
	}
	for _, reg := range out.Registrations {
		if active[reg.MID] {
			continue
		}
		active[reg.MID] = true
		class := midClass{
			MID: reg.MID, Handler: "", Isolation: []classEvidence{}, ReadOnly: []classEvidence{},
			Retry: []classEvidence{}, Transactions: []classTransaction{}, Writes: "UNKNOWN", ReceiptWrites: []string{}, StateWrites: []string{},
			UnboundedReads: []unboundedRead{}, Unknown: []string{"inactive fallback registration: no dispatcher route to trace"},
		}
		if reg.Owner != "" {
			class.System = reg.Owner
		}
		classes = append(classes, class)
	}
	sort.Slice(classes, func(i, j int) bool { return classes[i].MID < classes[j].MID })
	return classes
}

// isRunCall recognises tx.Runner.Run and generation.TimedRunner.Run by their
// Options and RetryPolicy arguments, not by the receiver name.
func (t *tracer) isRunCall(call *ast.CallExpr, pkg *tracePackage) bool {
	if len(call.Args) < 5 {
		return false
	}
	return namedTypeIs(pkg.info, call.Args[3], txPackagePath, "Options") &&
		namedTypeIs(pkg.info, call.Args[4], txPackagePath, "RetryPolicy")
}

func namedTypeIs(info *types.Info, expr ast.Expr, packagePath, name string) bool {
	value := info.Types[expr].Type
	if value == nil {
		return false
	}
	named := derefNamed(value)
	return named != nil && named.Obj().Pkg() != nil && named.Obj().Pkg().Path() == packagePath && named.Obj().Name() == name
}

func (t *tracer) callSite(call *ast.CallExpr) (string, int) {
	position := t.w.fset.Position(call.Pos())
	return t.w.relativeFilename(position.Filename), position.Line
}

func (t *tracer) observeCall(call *ast.CallExpr, pkg *tracePackage) {
	if t.class == nil {
		return
	}
	if selector, ok := unwrapCallFun(call.Fun).(*ast.SelectorExpr); ok && selector.Sel.Name == "PutTx" {
		file, line := t.callSite(call)
		t.class.recordReceipt(file + ":" + strconv.Itoa(line))
	}
	if !t.isRunCall(call, pkg) {
		return
	}
	file, line := t.callSite(call)
	run := classTransaction{Function: t.currentFunction.display(), File: file, Line: line}
	isolation, isolationKnown := t.isolationFrom(call.Args[3], pkg)
	if !isolationKnown {
		isolation = "UNKNOWN"
		t.class.noteMarker("transaction isolation not statically decidable at " + file + ":" + strconv.Itoa(line))
	}
	run.Isolation = isolation
	readOnly, readOnlyKnown := t.readOnlyFrom(call.Args[3], pkg)
	if !readOnlyKnown {
		readOnly = "UNKNOWN"
		t.class.noteMarker("transaction ReadOnly flag not statically decidable at " + file + ":" + strconv.Itoa(line))
	}
	run.ReadOnly = readOnly
	retry, retryKnown := t.maxAttemptsFrom(call.Args[4], pkg)
	if !retryKnown {
		retry = "UNKNOWN"
		t.class.noteMarker("transaction retry policy not statically decidable at " + file + ":" + strconv.Itoa(line))
	}
	run.Retry = retry
	t.class.addRun(run)
}

func (t *tracer) isolationFrom(expr ast.Expr, pkg *tracePackage) (string, bool) {
	options, ok := compositeOf(pkg.info, expr, txPackagePath, "Options")
	if !ok {
		return "", false
	}
	value := optionsField(options, "Isolation")
	if value == nil {
		return "unset", true
	}
	return isolationName(pkg.info.Types[value].Value)
}

func (t *tracer) readOnlyFrom(expr ast.Expr, pkg *tracePackage) (string, bool) {
	options, ok := compositeOf(pkg.info, expr, txPackagePath, "Options")
	if !ok {
		return "", false
	}
	value := optionsField(options, "ReadOnly")
	if value == nil {
		return "false", true
	}
	flag, ok := constantValue(pkg.info, value)
	if !ok || flag.Kind() != constant.Bool {
		return "", false
	}
	return strconv.FormatBool(constant.BoolVal(flag)), true
}

func (t *tracer) maxAttemptsFrom(expr ast.Expr, pkg *tracePackage) (string, bool) {
	if retry, ok := compositeOf(pkg.info, expr, txPackagePath, "RetryPolicy"); ok {
		return maxAttemptsLiteral(retry, pkg)
	}
	call, ok := unwrapExpr(expr).(*ast.CallExpr)
	if !ok {
		return "", false
	}
	targets, _ := t.targets(call, pkg)
	for _, target := range targets {
		targetPackage, ok := t.packageFor(target.pkgPath)
		if !ok {
			continue
		}
		declaration := targetPackage.decls[target.key()]
		if declaration == nil {
			continue
		}
		if value, found := retryReturned(declaration, targetPackage); found {
			return value, true
		}
	}
	return "", false
}

func retryReturned(decl *ast.FuncDecl, pkg *tracePackage) (string, bool) {
	found := ""
	ok := false
	ast.Inspect(decl.Body, func(node ast.Node) bool {
		if ok {
			return false
		}
		result, isReturn := node.(*ast.ReturnStmt)
		if !isReturn {
			return true
		}
		for _, expression := range result.Results {
			if retry, isLiteral := compositeOf(pkg.info, expression, txPackagePath, "RetryPolicy"); isLiteral {
				found, ok = maxAttemptsLiteral(retry, pkg)
				return false
			}
		}
		return true
	})
	return found, ok
}

func maxAttemptsLiteral(literal *ast.CompositeLit, pkg *tracePackage) (string, bool) {
	value := optionsField(literal, "MaxAttempts")
	if value == nil {
		return "0", true
	}
	number, ok := constantValue(pkg.info, value)
	if !ok || number.Kind() != constant.Int {
		return "", false
	}
	attempts, exact := constant.Int64Val(number)
	if !exact {
		return "", false
	}
	return strconv.FormatInt(attempts, 10), true
}

func compositeOf(info *types.Info, expr ast.Expr, packagePath, name string) (*ast.CompositeLit, bool) {
	expr = unwrapExpr(expr)
	literal, ok := expr.(*ast.CompositeLit)
	if !ok || !namedTypeIs(info, expr, packagePath, name) {
		return nil, false
	}
	return literal, true
}

func optionsField(literal *ast.CompositeLit, name string) ast.Expr {
	for _, element := range literal.Elts {
		pair, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := pair.Key.(*ast.Ident)
		if ok && key.Name == name {
			return pair.Value
		}
	}
	return nil
}

func constantValue(info *types.Info, expr ast.Expr) (constant.Value, bool) {
	value := info.Types[expr].Value
	if value == nil {
		return nil, false
	}
	return value, true
}

// isolationName maps the tx.Isolation constants. The numbers are the iota
// order in internal/foundation/tx/types.go; the names are what operators read.
func isolationName(value constant.Value) (string, bool) {
	if value == nil || value.Kind() != constant.Int {
		return "", false
	}
	number, exact := constant.Int64Val(value)
	if !exact {
		return "", false
	}
	switch number {
	case 1:
		return "read_committed", true
	case 2:
		return "repeatable_read", true
	case 3:
		return "serializable", true
	}
	return "", false
}

func unwrapExpr(expr ast.Expr) ast.Expr {
	for {
		parenthesized, ok := expr.(*ast.ParenExpr)
		if !ok {
			return expr
		}
		expr = parenthesized.X
	}
}

var (
	unboundedKey   = regexp.MustCompile(`(?i)\b(player_id|owner_player_id|actor_player_id|holder_id|lender_id|account_uid|account_id|uid|player_low_id|player_high_id|target_player_id|sender_player_id|recipient_player_id|context_id|session_id|session_ref|credential|token_hash|sid)\b`)
	unboundedLimit = regexp.MustCompile(`(?i)\blimit\b`)
	unboundedWhere = regexp.MustCompile(`(?i)\bwhere\b`)
)

// splitSQLStatements separates statements at semicolons and at newlines that
// begin a new SELECT/WITH, because joined literal fragments may omit the
// semicolon between two queries.
func splitSQLStatements(text string) []string {
	statements := []string{}
	for _, part := range strings.Split(text, ";") {
		current := ""
		for _, line := range strings.Split(part, "\n") {
			lower := strings.ToLower(strings.TrimSpace(line))
			startsStatement := strings.HasPrefix(lower, "select") || strings.HasPrefix(lower, "with")
			if current != "" && startsStatement {
				statements = append(statements, current)
				current = ""
			}
			if current == "" {
				current = line
				continue
			}
			current += "\n" + line
		}
		if strings.TrimSpace(current) != "" {
			statements = append(statements, current)
		}
	}
	return statements
}

// unboundedSQLStatements lists read statements with no LIMIT whose WHERE clause
// has no player/actor key. A missing WHERE is unbounded too.
func unboundedSQLStatements(text string) []string {
	statements := []string{}
	for _, raw := range splitSQLStatements(text) {
		statement := strings.Join(strings.Fields(raw), " ")
		lower := strings.ToLower(statement)
		if !strings.HasPrefix(lower, "select") && !strings.HasPrefix(lower, "with") {
			continue
		}
		if traceInsert.MatchString(statement) || traceUpdate.MatchString(statement) || traceDelete.MatchString(statement) {
			continue
		}
		if unboundedLimit.MatchString(statement) {
			continue
		}
		where := unboundedWhere.FindStringIndex(statement)
		if where != nil && unboundedKey.MatchString(statement[where[0]:]) {
			continue
		}
		statements = append(statements, statement)
	}
	return statements
}

// sortClassEvidenceSites is kept separate from class sorting for unit tests.
func sortClassEvidenceSites(values []classEvidence) {
	sort.SliceStable(values, func(i, j int) bool {
		if values[i].File != values[j].File {
			return values[i].File < values[j].File
		}
		return values[i].Line < values[j].Line
	})
}
