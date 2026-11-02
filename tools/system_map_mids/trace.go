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
	w         *typedWorld
	mid       int
	pkgs      map[string]*tracePackage
	visited   map[string]bool
	lines     []string
	nodes     int
	truncated bool
	limit     int
	boundary  string
	read      map[string]bool
	written   map[string]bool
}

func newTracer(w *typedWorld, mid int) *tracer {
	return &tracer{
		w: w, mid: mid, pkgs: map[string]*tracePackage{}, visited: map[string]bool{},
		read: map[string]bool{}, written: map[string]bool{},
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
		return
	}
	if t.visited[target.key()] || t.outsideBoundary(target.pkgPath) {
		return
	}
	if t.nodes >= t.nodeLimit() {
		t.truncated = true
		return
	}
	t.visited[target.key()] = true
	t.nodes++
	pkg, ok := t.packageFor(target.pkgPath)
	if !ok {
		t.line(depth, "UNRESOLVED "+target.display()+" ("+target.pkgPath+" type information unavailable)")
		return
	}
	decl := pkg.decls[target.key()]
	if decl == nil {
		t.line(depth, "UNRESOLVED "+target.display()+" (definition not found)")
		return
	}
	position := t.w.fset.Position(decl.Pos())
	prefix := target.display() + " " + t.w.relativeFilename(position.Filename) + ":" + strconv.Itoa(position.Line)
	if target.callFile != "" {
		prefix += "  at " + target.callFile + ":" + strconv.Itoa(target.callLine)
	}
	t.line(depth, prefix)
	t.sqlAndFacts(decl, pkg.declFile[decl], pkg, depth)
	if handler && t.mid >= 0 {
		t.walkHandlerBody(decl.Body.List, pkg, depth)
		return
	}
	t.inspectCalls(decl.Body, pkg, depth)
}

// walkHandlerBody follows only the MID case of a handler's MID switch, so a
// trace answers what the requested MID touches rather than every sibling MID.
func (t *tracer) walkHandlerBody(statements []ast.Stmt, pkg *tracePackage, depth int) {
	for _, statement := range statements {
		switch typed := statement.(type) {
		case *ast.SwitchStmt:
			if typed.Tag == nil || !strings.Contains(t.expressionText(pkg, typed.Tag), "MID") {
				t.inspectCalls(statement, pkg, depth)
				continue
			}
			if typed.Init != nil {
				t.inspectCalls(typed.Init, pkg, depth)
			}
			for _, raw := range typed.Body.List {
				clause, isClause := raw.(*ast.CaseClause)
				if !isClause || !t.clauseMatchesMID(clause, pkg) {
					continue
				}
				for _, inner := range clause.Body {
					t.inspectCalls(inner, pkg, depth)
				}
			}
		default:
			t.inspectCalls(statement, pkg, depth)
		}
	}
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
		children, unresolved := t.targets(call, pkg)
		if unresolved != "" {
			t.line(depth+1, "UNRESOLVED "+unresolved)
		}
		if len(children) > traceFanoutLimit {
			t.line(depth+1, fanoutLine(children))
			return true
		}
		for _, child := range children {
			if strings.HasPrefix(child.name, "Push") {
				t.line(depth+1, "push: "+child.pkgPath+"."+child.name)
			}
			t.walk(child, depth+1, false)
		}
		return true
	})
}

var (
	traceInsert = regexp.MustCompile(`(?i)\binsert\s+into\s+([a-zA-Z0-9_".]+)`)
	traceUpdate = regexp.MustCompile(`(?i)\bupdate\s+([a-zA-Z0-9_".]+)(?:\s+(?:as\s+)?[a-z][a-zA-Z0-9_]*)?\s+set\b`)
	traceDelete = regexp.MustCompile(`(?i)\bdelete\s+from\s+([a-zA-Z0-9_".]+)`)
	traceRead   = regexp.MustCompile(`(?i)\bfrom\s+([a-zA-Z0-9_".]+)`)
	traceLock   = regexp.MustCompile(`(?is)for\s+(update|share)`)
)

var traceKeywords = map[string]bool{
	"select": true, "where": true, "set": true, "values": true, "lateral": true,
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

func traceSQLTables(text string) ([]string, []string, []string) {
	read := map[string]bool{}
	write := map[string]bool{}
	locks := map[string]bool{}
	for _, pattern := range []*regexp.Regexp{traceInsert, traceUpdate, traceDelete} {
		for _, match := range pattern.FindAllStringSubmatchIndex(text, -1) {
			if table := traceTableName(text[match[2]:match[3]]); table != "" {
				write[table] = true
			}
		}
	}
	for _, match := range traceRead.FindAllStringSubmatchIndex(text, -1) {
		if traceSkipFunction(text, match) {
			continue
		}
		if table := traceTableName(text[match[2]:match[3]]); table != "" {
			read[table] = true
		}
	}
	for _, location := range traceLock.FindAllStringSubmatchIndex(text, -1) {
		start := location[0] - 800
		if start < 0 {
			start = 0
		}
		tables := lockTable.FindAllStringSubmatch(text[start:location[0]], -1)
		if len(tables) == 0 {
			continue
		}
		table := traceTableName(tables[len(tables)-1][1])
		kind := strings.ToUpper(text[location[2]:location[3]])
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

func (t *tracer) sqlAndFacts(decl *ast.FuncDecl, file *ast.File, pkg *tracePackage, depth int) {
	literals := []string{}
	ast.Inspect(decl.Body, func(node ast.Node) bool {
		if identifier, isIdentifier := node.(*ast.Ident); isIdentifier {
			named, isConstant := pkg.info.Uses[identifier].(*types.Const)
			if isConstant && named.Val().Kind() == constant.String {
				literals = append(literals, constant.StringVal(named.Val()))
			}
			return true
		}
		literal, ok := node.(*ast.BasicLit)
		if !ok || literal.Kind != token.STRING {
			return true
		}
		value, err := strconv.Unquote(literal.Value)
		if err == nil {
			literals = append(literals, value)
		}
		return true
	})
	read, write, locks := traceSQLTables(strings.Join(literals, "\n"))
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
		parts = append(parts, "lock "+strings.Join(locks, ", "))
	}
	if len(parts) > 0 {
		t.line(depth+1, "sql: "+strings.Join(parts, "; "))
	}
	if kinds := factKindsInFunction(decl, file, pkg.info); len(kinds) > 0 {
		t.line(depth+1, "facts: "+strings.Join(kinds, ", "))
	}
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
	lines := append([]string{header}, handler.lines...)
	if handler.truncated {
		lines = append(lines, fmt.Sprintf("BOUND stopped after %d functions", traceNodeLimit))
	}
	return strings.Join(lines, "\n") + "\n", nil
}

func pathBase(path string) string {
	parts := strings.Split(path, "/")
	return parts[len(parts)-1]
}
