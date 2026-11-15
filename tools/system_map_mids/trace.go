package main

import (
	"fmt"
	"go/ast"
	"go/constant"
	"go/token"
	"go/types"
	"os"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

const (
	traceNodeLimit       = 2000
	systemTableNodeLimit = 20000
	traceDepthLimit      = 40
	// An interface with more implementers than this is a registry, not one
	// path; following all of them would bury the route the request really takes.
	traceFanoutLimit = 3
)

type traceTarget struct {
	pkgPath  string
	receiver string
	name     string
	callFile string
	callLine int
}

func (t traceTarget) key() string {
	return t.pkgPath + "\x00" + t.receiver + "\x00" + t.name
}

func (t traceTarget) display() string {
	if t.receiver == "" {
		return t.name
	}
	return t.receiver + "." + t.name
}

type tracePackage struct {
	info     *types.Info
	files    []*ast.File
	decls    map[string]*ast.FuncDecl
	declFile map[*ast.FuncDecl]*ast.File
	text     map[string]string
}

type tracer struct {
	w             *typedWorld
	mid           int
	pkgs          map[string]*tracePackage
	visited       map[string]bool
	lines         []string
	nodes         int
	truncated     bool
	touchesTables map[string]bool
	limit         int
	boundary      string
	read          map[string]bool
	written       map[string]bool

	// C1-3a classification. class is nil for a plain trace; skipRunnerInternals
	// keeps the class walk out of tx.Runner.Run's retry/cancel machinery, whose
	// internals say nothing about what the route writes.
	class               *classBuilder
	skipRunnerInternals bool
	currentFunction     traceTarget
}

func newTracer(w *typedWorld, mid int) *tracer {
	return &tracer{
		w: w, mid: mid, pkgs: map[string]*tracePackage{}, visited: map[string]bool{},
		read: map[string]bool{}, written: map[string]bool{}, touchesTables: map[string]bool{},
	}
}

// outsideBoundary stops a system's table walk at another application system,
// whose tables are its own; the system's calls name that dependency.
func (t *tracer) outsideBoundary(path string) bool {
	if t.boundary == "" || path == t.boundary || strings.HasPrefix(path, t.boundary+"/") {
		return false
	}
	return strings.HasPrefix(path, modulePath+"internal/application/")
}

func fanoutLine(children []traceTarget) string {
	names := []string{}
	for _, child := range children {
		names = append(names, pathBase(child.pkgPath)+"."+child.display())
	}
	sort.Strings(names)
	return fmt.Sprintf("FANOUT %s has %d implementers, not followed: %s", children[0].name, len(children), strings.Join(names, ", "))
}

// systemTables returns what one system's own code and the store methods it
// actually reaches read and write.
func systemTables(w *typedWorld, path string) (typedTables, error) {
	walker := newTracer(w, -1)
	walker.boundary = path
	walker.limit = systemTableNodeLimit
	pkg, ok := walker.packageFor(path)
	if !ok {
		return typedTables{}, fmt.Errorf("%s: type information unavailable", path)
	}
	keys := []string{}
	for key := range pkg.decls {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		parts := strings.Split(key, "\x00")
		walker.walk(traceTarget{pkgPath: parts[0], receiver: parts[1], name: parts[2]}, 0, false)
	}
	if walker.truncated {
		return typedTables{}, fmt.Errorf("%s: table walk hit a bound", path)
	}
	return typedTables{Read: sortedKeys(walker.read), Written: sortedKeys(walker.written)}, nil
}

func functionKey(fn *types.Func) string {
	receiver := ""
	if signature, ok := fn.Type().(*types.Signature); ok && signature.Recv() != nil {
		if named := derefNamed(signature.Recv().Type()); named != nil {
			receiver = named.Obj().Name()
		}
	}
	return fn.Pkg().Path() + "\x00" + receiver + "\x00" + fn.Name()
}

func (t *tracer) nodeLimit() int {
	if t.limit > 0 {
		return t.limit
	}
	return traceNodeLimit
}

func (t *tracer) packageFor(path string) (*tracePackage, bool) {
	if pkg, ok := t.pkgs[path]; ok {
		return pkg, pkg != nil
	}
	if pkg, ok := t.w.traceCache[path]; ok {
		t.pkgs[path] = pkg
		return pkg, pkg != nil
	}
	listed, ok := t.w.packages[path]
	if !ok {
		t.pkgs[path] = nil
		return nil, false
	}
	info, files := t.w.check(listed)
	if info == nil {
		t.pkgs[path] = nil
		return nil, false
	}
	pkg := &tracePackage{
		info: info, files: files,
		decls: map[string]*ast.FuncDecl{}, declFile: map[*ast.FuncDecl]*ast.File{}, text: map[string]string{},
	}
	for _, file := range files {
		ast.Inspect(file, func(node ast.Node) bool {
			decl, isDecl := node.(*ast.FuncDecl)
			if !isDecl || decl.Body == nil {
				return true
			}
			function, isFunction := info.Defs[decl.Name].(*types.Func)
			if !isFunction {
				return true
			}
			pkg.decls[functionKey(function)] = decl
			pkg.declFile[decl] = file
			return true
		})
	}
	if t.w.traceCache == nil {
		t.w.traceCache = map[string]*tracePackage{}
	}
	t.w.traceCache[path] = pkg
	t.pkgs[path] = pkg
	return pkg, true
}

func moduleTarget(function *types.Func, callFile string, callLine int) []traceTarget {
	if function.Pkg() == nil || !strings.HasPrefix(function.Pkg().Path(), modulePath) {
		return nil
	}
	receiver := ""
	if signature, ok := function.Type().(*types.Signature); ok && signature.Recv() != nil {
		if named := derefNamed(signature.Recv().Type()); named != nil {
			receiver = named.Obj().Name()
		}
	}
	return []traceTarget{{pkgPath: function.Pkg().Path(), receiver: receiver, name: function.Name(), callFile: callFile, callLine: callLine}}
}

func (t *tracer) interfaceTargets(iface *types.Interface, name, method, callFile string, callLine int) []traceTarget {
	seen := map[string]bool{}
	targets := []traceTarget{}
	for _, named := range t.w.implementerTypes(iface, name) {
		for _, methodSet := range []*types.MethodSet{types.NewMethodSet(types.NewPointer(named)), types.NewMethodSet(named)} {
			selection := methodSet.Lookup(nil, method)
			if selection == nil {
				continue
			}
			function, ok := selection.Obj().(*types.Func)
			if !ok {
				continue
			}
			for _, target := range moduleTarget(function, callFile, callLine) {
				if !seen[target.key()] {
					seen[target.key()] = true
					targets = append(targets, target)
				}
			}
			break
		}
	}
	return targets
}

func unwrapCallFun(expr ast.Expr) ast.Expr {
	for {
		switch typed := expr.(type) {
		case *ast.ParenExpr:
			expr = typed.X
		case *ast.IndexExpr:
			expr = typed.X
		case *ast.IndexListExpr:
			expr = typed.X
		default:
			return expr
		}
	}
}

// targets resolves a call to module functions. The second result is a
// non-empty expression only when a function value or dynamic route is opaque.
func (t *tracer) targets(call *ast.CallExpr, pkg *tracePackage) ([]traceTarget, string) {
	callFile := t.w.relativeFilename(t.w.fset.Position(call.Pos()).Filename)
	callLine := t.w.fset.Position(call.Pos()).Line
	fun := unwrapCallFun(call.Fun)
	switch typed := fun.(type) {
	case *ast.Ident:
		object := pkg.info.Uses[typed]
		if function, ok := object.(*types.Func); ok {
			return moduleTarget(function, callFile, callLine), ""
		}
		if _, ok := object.(*types.Builtin); ok {
			return nil, ""
		}
		if value := pkg.info.Types[typed].Type; value != nil {
			if _, isSignature := value.Underlying().(*types.Signature); isSignature {
				return nil, t.expressionText(pkg, typed)
			}
		}
		return nil, ""
	case *ast.SelectorExpr:
		if selection := pkg.info.Selections[typed]; selection != nil {
			function, ok := selection.Obj().(*types.Func)
			if !ok {
				return nil, ""
			}
			receiver := selection.Recv()
			if named := derefNamed(receiver); named != nil {
				if interfaceType, isInterface := named.Underlying().(*types.Interface); isInterface {
					if !interfaceAllowed(named, interfaceType) {
						return nil, ""
					}
					name := "anonymous"
					if named.Obj().Pkg() != nil {
						name = named.Obj().Pkg().Path() + "." + named.Obj().Name()
					}
					return t.interfaceTargets(interfaceType, name, function.Name(), callFile, callLine), ""
				}
				return moduleTarget(function, callFile, callLine), ""
			}
			if interfaceType, isInterface := receiver.Underlying().(*types.Interface); isInterface {
				if !interfaceAllowed(nil, interfaceType) {
					return nil, ""
				}
				return t.interfaceTargets(interfaceType, "", function.Name(), callFile, callLine), ""
			}
			return nil, ""
		}
		if function, ok := pkg.info.Uses[typed.Sel].(*types.Func); ok {
			return moduleTarget(function, callFile, callLine), ""
		}
		if value := pkg.info.Types[typed].Type; value != nil {
			if _, isSignature := value.Underlying().(*types.Signature); isSignature {
				return nil, t.expressionText(pkg, typed)
			}
		}
		return nil, ""
	}
	return nil, ""
}

func (t *tracer) expressionText(pkg *tracePackage, expr ast.Expr) string {
	start := t.w.fset.Position(expr.Pos())
	end := t.w.fset.Position(expr.End())
	if start.Filename != end.Filename || start.Offset < 0 || end.Offset < start.Offset {
		return "?"
	}
	text, ok := pkg.text[start.Filename]
	if !ok {
		raw, err := os.ReadFile(start.Filename)
		if err != nil {
			return "?"
		}
		text = string(raw)
		pkg.text[start.Filename] = text
	}
	if end.Offset > len(text) {
		return "?"
	}
	snippet := strings.Join(strings.Fields(text[start.Offset:end.Offset]), " ")
	if len(snippet) > 80 {
		snippet = snippet[:80] + "..."
	}
	return snippet
}

func (t *tracer) line(depth int, value string) {
	t.lines = append(t.lines, strings.Repeat("  ", depth)+value)
}

func (t *tracer) walk(target traceTarget, depth int, handler bool) {
	if t.truncated {
		return
	}
	if depth > traceDepthLimit {
		t.truncated = true
		t.line(depth, fmt.Sprintf("BOUND depth %d reached", traceDepthLimit))
		t.mark(fmt.Sprintf("BOUND depth %d", traceDepthLimit))
		return
	}
	if t.outsideBoundary(target.pkgPath) {
		return
	}
	if t.visited[target.key()] {
		if t.touchesTables[target.key()] {
			t.line(depth, target.display()+" (seen above, touches tables)  at "+target.callFile+":"+strconv.Itoa(target.callLine))
		}
		return
	}
	if t.nodes >= t.nodeLimit() {
		t.truncated = true
		t.mark(fmt.Sprintf("BOUND node limit %d", t.nodeLimit()))
		return
	}
	t.visited[target.key()] = true
	t.nodes++
	pkg, ok := t.packageFor(target.pkgPath)
	if !ok {
		t.line(depth, "UNRESOLVED "+target.display()+" ("+target.pkgPath+" type information unavailable)")
		t.mark("UNRESOLVED " + target.display() + " (type information unavailable)")
		return
	}
	decl := pkg.decls[target.key()]
	if decl == nil {
		t.line(depth, "UNRESOLVED "+target.display()+" (definition not found)")
		t.mark("UNRESOLVED " + target.display() + " (definition not found)")
		return
	}
	position := t.w.fset.Position(decl.Pos())
	prefix := target.display() + " " + t.w.relativeFilename(position.Filename) + ":" + strconv.Itoa(position.Line)
	if target.callFile != "" {
		prefix += "  at " + target.callFile + ":" + strconv.Itoa(target.callLine)
	}
	t.line(depth, prefix)
	previousFunction := t.currentFunction
	t.currentFunction = target
	defer func() { t.currentFunction = previousFunction }()
	first := len(t.lines)
	defer func() {
		for _, line := range t.lines[first:] {
			if strings.Contains(line, "sql: ") || strings.Contains(line, "(seen above, touches tables)") {
				t.touchesTables[target.key()] = true
				return
			}
		}
	}()
	t.sqlAndFacts(decl, pkg.declFile[decl], pkg, depth)
	if handler && t.mid >= 0 {
		t.walkHandlerBody(decl.Body.List, pkg, depth)
		return
	}
	t.inspectCalls(decl.Body, pkg, depth)
}

// walkHandlerBody follows only the MID case of a handler's MID switch, so a
// trace answers what the requested MID touches rather than every sibling MID.
func (t *tracer) walkHandlerBody(statements []ast.Stmt, pkg *tracePackage, depth int) bool {
	for _, statement := range statements {
		switch branch := statement.(type) {
		case *ast.ReturnStmt:
			t.inspectCalls(branch, pkg, depth)
			return true
		case *ast.IfStmt:
			matches, known := t.midCondition(branch.Cond, pkg)
			if !known {
				t.inspectCalls(branch, pkg, depth)
				continue
			}
			if branch.Init != nil {
				t.inspectCalls(branch.Init, pkg, depth)
			}
			if matches {
				if t.walkHandlerBody(branch.Body.List, pkg, depth) {
					return true
				}
			} else if block, ok := branch.Else.(*ast.BlockStmt); ok {
				if t.walkHandlerBody(block.List, pkg, depth) {
					return true
				}
			} else if branch.Else != nil {
				if t.walkHandlerBody([]ast.Stmt{branch.Else}, pkg, depth) {
					return true
				}
			}
		case *ast.SwitchStmt:
			if branch.Tag == nil || !strings.Contains(t.expressionText(pkg, branch.Tag), "MID") {
				t.inspectCalls(branch, pkg, depth)
				continue
			}
			if branch.Init != nil {
				t.inspectCalls(branch.Init, pkg, depth)
			}
			for _, raw := range branch.Body.List {
				clause, ok := raw.(*ast.CaseClause)
				if ok && t.clauseMatchesMID(clause, pkg) {
					if t.walkHandlerBody(clause.Body, pkg, depth) {
						return true
					}
				}
			}
		default:
			t.inspectCalls(statement, pkg, depth)
		}
	}
	return false
}

func (t *tracer) midCondition(expression ast.Expr, pkg *tracePackage) (bool, bool) {
	comparison, ok := expression.(*ast.BinaryExpr)
	if !ok || (comparison.Op != token.EQL && comparison.Op != token.NEQ) {
		return false, false
	}
	left, right := comparison.X, comparison.Y
	selector, ok := left.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != "MID" {
		left, right = right, left
		selector, ok = left.(*ast.SelectorExpr)
	}
	if !ok || selector.Sel.Name != "MID" {
		return false, false
	}
	value := pkg.info.Types[right].Value
	if value == nil || value.Kind() != constant.Int {
		return false, false
	}
	mid, exact := constant.Int64Val(value)
	if !exact {
		return false, false
	}
	matches := mid == int64(t.mid)
	if comparison.Op == token.NEQ {
		matches = !matches
	}
	return matches, true
}

func (t *tracer) clauseMatchesMID(clause *ast.CaseClause, pkg *tracePackage) bool {
	for _, expression := range clause.List {
		value := pkg.info.Types[expression].Value
		if value == nil || value.Kind() != constant.Int {
			continue
		}
		if mid, exact := constant.Int64Val(value); exact && mid == int64(t.mid) {
			return true
		}
	}
	return false
}

func (t *tracer) inspectCalls(node ast.Node, pkg *tracePackage, depth int) {
	ast.Inspect(node, func(inner ast.Node) bool {
		call, isCall := inner.(*ast.CallExpr)
		if !isCall {
			return true
		}
		t.observeCall(call, pkg)
		runCall := t.skipRunnerInternals && t.isRunCall(call, pkg)
		children, unresolved := t.targets(call, pkg)
		if unresolved != "" {
			t.line(depth+1, "UNRESOLVED "+unresolved)
			t.mark("UNRESOLVED " + unresolved)
		}
		if len(children) > traceFanoutLimit {
			line := fanoutLine(children)
			t.line(depth+1, line)
			t.mark(line)
			return true
		}
		for _, child := range children {
			if runCall && (child.pkgPath == txPackagePath || child.pkgPath == generationPackagePath) {
				continue
			}
			if strings.HasPrefix(child.name, "Push") {
				t.line(depth+1, "push: "+child.pkgPath+"."+child.name)
			}
			t.walk(child, depth+1, false)
		}
		return true
	})
}

func (t *tracer) mark(reason string) {
	if t.class != nil {
		t.class.noteMarker(reason)
	}
}

var (
	traceInsert = regexp.MustCompile(`(?i)\binsert\s+into\s+([a-zA-Z0-9_".]+)`)
	traceUpdate = regexp.MustCompile(`(?i)\bupdate\s+([a-zA-Z0-9_".]+)(?:\s+(?:as\s+)?[a-z][a-zA-Z0-9_]*)?\s+set\b`)
	traceDelete = regexp.MustCompile(`(?i)\bdelete\s+from\s+([a-zA-Z0-9_".]+)`)
	traceRead   = regexp.MustCompile(`(?i)\b(?:from|join)\s+([a-zA-Z0-9_".]+)`)
	traceLock   = regexp.MustCompile(`(?is)\bfor\s+(update|share)(?:\s+of\s+([a-zA-Z0-9_".]+(?:\s*,\s*[a-zA-Z0-9_".]+)*))?`)
)

var traceKeywords = map[string]bool{
	"select": true, "where": true, "set": true, "values": true, "lateral": true,
	"join": true, "update": true,
}

func traceTableName(raw string) string {
	name := strings.ToLower(normalizeTableName(raw))
	if traceKeywords[name] {
		return ""
	}
	return name
}

func traceSkipFunction(text string, match []int) bool {
	for index := match[1]; index < len(text); index++ {
		if text[index] == ' ' || text[index] == '\n' || text[index] == '\t' {
			continue
		}
		return text[index] == '('
	}
	return false
}

var sqlFragment = regexp.MustCompile(`(?i)^\s*(?:select\b|insert\b|update\b|delete\b|with\b|from\b|join\b|for\s+(?:update|share)\b)`)

var sqlLeadingComments = regexp.MustCompile(`(?s)^(?:\s|--[^\n]*(?:\n|$)|/\*.*?\*/)*`)

func isSQLFragment(text string) bool {
	return sqlFragment.MatchString(sqlLeadingComments.ReplaceAllString(text, ""))
}

var traceRelation = regexp.MustCompile(`(?i)\b(?:from|join)\s+([a-zA-Z0-9_".]+)`)
var traceRelationAlias = regexp.MustCompile(`(?i)^\s+(?:as\s+)?([a-zA-Z0-9_"]+)`)

func lockRelationAliases(text string) map[string]string {
	aliases := map[string]string{}
	for _, match := range traceRelation.FindAllStringSubmatchIndex(text, -1) {
		table := traceTableName(text[match[2]:match[3]])
		aliases[table] = table
		alias := traceRelationAlias.FindStringSubmatch(text[match[1]:])
		if len(alias) == 0 {
			continue
		}
		name := strings.ToLower(normalizeTableName(alias[1]))
		switch name {
		case "where", "join", "inner", "left", "right", "full", "cross", "on", "for", "order", "group", "limit", "union":
			continue
		}
		aliases[name] = table
	}
	return aliases
}

var traceCTEAlias = regexp.MustCompile(`(?i)(?:\bwith\s+(?:recursive\s+)?|,)\s*([a-zA-Z0-9_"]+)\s*(?:\([^)]*\)\s*)?as\s+(?:(?:not\s+)?materialized\s*)?\(`)

func traceSQLTables(text string) ([]string, []string, []string) {
	if !isSQLFragment(text) {
		return nil, nil, nil
	}
	read := map[string]bool{}
	write := map[string]bool{}
	locks := map[string]bool{}
	aliases := map[string]bool{}
	for _, match := range traceCTEAlias.FindAllStringSubmatch(text, -1) {
		aliases[traceTableName(match[1])] = true
	}
	writeText := traceLock.ReplaceAllString(text, "")
	for _, pattern := range []*regexp.Regexp{traceInsert, traceUpdate, traceDelete} {
		for _, match := range pattern.FindAllStringSubmatchIndex(writeText, -1) {
			if table := traceTableName(writeText[match[2]:match[3]]); table != "" {
				write[table] = true
			}
		}
	}
	for offset := 0; offset < len(text); {
		match := traceRead.FindStringSubmatchIndex(text[offset:])
		if len(match) == 0 {
			break
		}
		for index, position := range match {
			if position >= 0 {
				match[index] = offset + position
			}
		}
		if !traceSkipFunction(text, match) {
			raw := text[match[2]:match[3]]
			table := traceTableName(raw)
			if table != "" && (!aliases[table] || strings.Contains(raw, ".")) {
				read[table] = true
			}
		}
		offset = match[0] + 1
	}
	for _, location := range traceLock.FindAllStringSubmatchIndex(text, -1) {
		start := location[0] - 800
		if start < 0 {
			start = 0
		}
		window := text[start:location[0]]
		kind := strings.ToUpper(text[location[2]:location[3]])
		if len(location) > 4 && location[4] >= 0 {
			aliases := lockRelationAliases(window)
			targets := []string{}
			for _, raw := range strings.Split(text[location[4]:location[5]], ",") {
				target := aliases[strings.ToLower(normalizeTableName(strings.TrimSpace(raw)))]
				if target == "" {
					targets = nil
					break
				}
				targets = append(targets, target)
			}
			for _, table := range targets {
				locks[table+" FOR "+kind] = true
			}
			continue
		}
		tables := lockTable.FindAllStringSubmatch(window, -1)
		if len(tables) == 0 {
			continue
		}
		table := traceTableName(tables[len(tables)-1][1])
		if table != "" {
			locks[table+" FOR "+kind] = true
		}
	}
	return sortedKeys(read), sortedKeys(write), sortedKeys(locks)
}

func sortedKeys(values map[string]bool) []string {
	keys := []string{}
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func functionSQLText(decl *ast.FuncDecl, info *types.Info) string {
	literals := []string{}
	ast.Inspect(decl.Body, func(node ast.Node) bool {
		if expression, ok := node.(ast.Expr); ok {
			value := info.Types[expression].Value
			if value != nil && value.Kind() == constant.String {
				text := constant.StringVal(value)
				if isSQLFragment(text) {
					literals = append(literals, text)
					return false
				}
			}
		}
		if identifier, isIdentifier := node.(*ast.Ident); isIdentifier {
			named, isConstant := info.Uses[identifier].(*types.Const)
			if isConstant && named.Val().Kind() == constant.String {
				value := constant.StringVal(named.Val())
				if isSQLFragment(value) {
					literals = append(literals, value)
				}
			}
			return true
		}
		literal, ok := node.(*ast.BasicLit)
		if !ok || literal.Kind != token.STRING {
			return true
		}
		value, err := strconv.Unquote(literal.Value)
		if err == nil && isSQLFragment(value) {
			literals = append(literals, value)
		}
		return true
	})
	return strings.Join(literals, "\n")
}

func (t *tracer) sqlAndFacts(decl *ast.FuncDecl, file *ast.File, pkg *tracePackage, depth int) {
	text := functionSQLText(decl, pkg.info)
	read, write, locks := traceSQLTables(text)
	if t.class != nil {
		position := t.w.fset.Position(decl.Pos())
		site := t.w.relativeFilename(position.Filename) + ":" + strconv.Itoa(position.Line)
		// The receipt store's own insert is the receipt class, not a state write.
		if len(write) > 0 && decl.Name.Name != "PutTx" {
			t.class.recordStateWrite(site)
		}
		for _, statement := range unboundedSQLStatements(text) {
			t.class.recordUnbounded(unboundedRead{Statement: statement, File: t.w.relativeFilename(position.Filename), Line: position.Line})
		}
	}
	if len(locks) == 0 && traceLock.MatchString(text) {
		t.line(depth+1, "UNRESOLVED SQL lock target; clause passed or assembled outside this function")
	}
	for _, table := range read {
		t.read[table] = true
	}
	for _, table := range write {
		t.written[table] = true
	}
	parts := []string{}
	if len(read) > 0 {
		parts = append(parts, "read "+strings.Join(read, ", "))
	}
	if len(write) > 0 {
		parts = append(parts, "write "+strings.Join(write, ", "))
	}
	if len(locks) > 0 {
		parts = append(parts, lockWord(decl)+strings.Join(locks, ", "))
	}
	if len(parts) > 0 {
		t.line(depth+1, "sql: "+strings.Join(parts, "; "))
	}
	if kinds := factKindsInFunction(decl, file, pkg.info); len(kinds) > 0 {
		t.line(depth+1, "facts: "+strings.Join(kinds, ", "))
	}
}

// lockWord says when the lock clause is appended under a branch, so the caller's
// argument decides whether the row is really locked.
func lockWord(decl *ast.FuncDecl) string {
	word := "lock "
	ast.Inspect(decl.Body, func(node ast.Node) bool {
		branch, isBranch := node.(*ast.IfStmt)
		if !isBranch {
			return true
		}
		ast.Inspect(branch.Body, func(inner ast.Node) bool {
			literal, isLiteral := inner.(*ast.BasicLit)
			if isLiteral && traceLock.MatchString(literal.Value) {
				word = "conditional lock "
			}
			return true
		})
		return true
	})
	return word
}

func factKindsInFunction(decl *ast.FuncDecl, file *ast.File, info *types.Info) []string {
	assignments := fileAssignments(file)
	found := map[string]bool{}
	ast.Inspect(decl.Body, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok {
			return true
		}
		selector, isSelector := call.Fun.(*ast.SelectorExpr)
		if !isSelector || selector.Sel.Name != "RecordTx" {
			return true
		}
		for _, argument := range call.Args {
			literal := factLiteral(argument, assignments)
			if literal == nil {
				continue
			}
			for _, element := range literal.Elts {
				pair, isPair := element.(*ast.KeyValueExpr)
				if !isPair {
					continue
				}
				key, isIdent := pair.Key.(*ast.Ident)
				if !isIdent || key.Name != "Kind" {
					continue
				}
				for _, value := range constStrings(pair.Value, assignments, info, 0) {
					found[value] = true
				}
			}
		}
		return true
	})
	return sortedKeys(found)
}

func traceMID(out *output, w *typedWorld, mid int) (string, error) {
	var chosen *registration
	for index := range out.Registrations {
		candidate := &out.Registrations[index]
		if candidate.MID != mid || candidate.Fallback || candidate.DispatcherPackage == "" || candidate.HandlerFile == "" {
			continue
		}
		chosen = candidate
		break
	}
	if chosen == nil {
		return "", fmt.Errorf("MID %d has no registered handler", mid)
	}
	handler := newTracer(w, mid)
	handler.walk(traceTarget{pkgPath: chosen.DispatcherPackage, receiver: chosen.DispatcherType, name: "Dispatch"}, 0, true)
	header := fmt.Sprintf("MID %d handler %s.%s %s:%d",
		mid, pathBase(chosen.DispatcherPackage), chosen.DispatcherType, chosen.HandlerFile, chosen.HandlerLine)
	lines := []string{header}
	for _, wrapper := range chosen.Wrappers {
		lines = append(lines, fmt.Sprintf("UNRESOLVED registered wrapper %s at %s:%d; inner-dispatcher trace omits wrapper effects", wrapper, chosen.RegistrationFile, chosen.RegistrationLine))
	}
	lines = append(lines, handler.lines...)
	if handler.truncated {
		lines = append(lines, fmt.Sprintf("BOUND stopped after %d functions", traceNodeLimit))
	}
	return strings.Join(lines, "\n") + "\n", nil
}

func pathBase(path string) string {
	parts := strings.Split(path, "/")
	return parts[len(parts)-1]
}
