// Command system_map_mids extracts HTTP MID registrations, their dispatchers and
// application owners, plus realtime S2C registrations, for tools/system_map.py.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

const modulePath = "gxb.local/backend/v2/"

type fileContext struct {
	rel     string
	pkgPath string
	imports map[string]string
	ast     *ast.File
}

type binding struct {
	expr     ast.Expr
	index    int
	typeExpr ast.Expr
	file     *fileContext
	midList  []int
}

type scope struct {
	parent *scope
	values map[string]binding
}

func newScope(parent *scope) *scope {
	return &scope{parent: parent, values: map[string]binding{}}
}

func (s *scope) lookup(name string) (binding, bool) {
	for current := s; current != nil; current = current.parent {
		if value, ok := current.values[name]; ok {
			return value, true
		}
	}
	return binding{}, false
}

type funcDef struct {
	file *fileContext
	node *ast.FuncDecl
}

type packageInfo struct {
	files   []*fileContext
	types   map[string]*fileContext
	funcs   map[string]funcDef
	methods map[string]funcDef
	vars    map[string]binding
}

type world struct {
	fset     *token.FileSet
	root     string
	packages map[string]*packageInfo
}

func (w *world) packageAt(path string) *packageInfo {
	if pkg, ok := w.packages[path]; ok {
		return pkg
	}
	dir := filepath.Join(w.root, strings.TrimPrefix(path, modulePath))
	pkg, err := w.loadPackage(path, dir)
	if err != nil {
		pkg = &packageInfo{types: map[string]*fileContext{}, funcs: map[string]funcDef{}, methods: map[string]funcDef{}, vars: map[string]binding{}}
	}
	w.packages[path] = pkg
	return pkg
}

func (w *world) loadPackage(path, dir string) (*packageInfo, error) {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	pkg := &packageInfo{types: map[string]*fileContext{}, funcs: map[string]funcDef{}, methods: map[string]funcDef{}, vars: map[string]binding{}}
	names := []string{}
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		full := filepath.Join(dir, name)
		parsed, err := parser.ParseFile(w.fset, full, nil, 0)
		if err != nil {
			continue
		}
		rel := strings.TrimPrefix(filepath.ToSlash(filepath.Join(dir, name)), strings.TrimSuffix(filepath.ToSlash(w.root), "/")+"/")
		fc := &fileContext{rel: rel, pkgPath: path, imports: map[string]string{}, ast: parsed}
		for _, spec := range parsed.Imports {
			importPath := strings.Trim(spec.Path.Value, `"`)
			alias := ""
			if spec.Name != nil {
				alias = spec.Name.Name
			} else {
				parts := strings.Split(importPath, "/")
				alias = parts[len(parts)-1]
			}
			if alias == "_" || alias == "." {
				continue
			}
			fc.imports[alias] = importPath
		}
		pkg.files = append(pkg.files, fc)
		for _, decl := range parsed.Decls {
			switch typed := decl.(type) {
			case *ast.GenDecl:
				for _, raw := range typed.Specs {
					switch spec := raw.(type) {
					case *ast.TypeSpec:
						pkg.types[spec.Name.Name] = fc
					case *ast.ValueSpec:
						for index, ident := range spec.Names {
							value := binding{file: fc}
							if len(spec.Values) == 1 {
								value.expr = spec.Values[0]
								value.index = index
							} else if index < len(spec.Values) {
								value.expr = spec.Values[index]
							} else {
								value.typeExpr = spec.Type
							}
							pkg.vars[ident.Name] = value
						}
					}
				}
			case *ast.FuncDecl:
				if typed.Recv == nil {
					pkg.funcs[typed.Name.Name] = funcDef{file: fc, node: typed}
					continue
				}
				receiver := receiverName(typed)
				if receiver != "" {
					pkg.methods[receiver+"."+typed.Name.Name] = funcDef{file: fc, node: typed}
				}
			}
		}
	}
	return pkg, nil
}

func receiverName(decl *ast.FuncDecl) string {
	if decl.Recv == nil || len(decl.Recv.List) == 0 {
		return ""
	}
	return typeName(decl.Recv.List[0].Type)
}

func typeName(expr ast.Expr) string {
	switch typed := expr.(type) {
	case *ast.Ident:
		return typed.Name
	case *ast.StarExpr:
		return typeName(typed.X)
	case *ast.IndexExpr:
		return typeName(typed.X)
	case *ast.IndexListExpr:
		return typeName(typed.X)
	case *ast.SelectorExpr:
		return typed.Sel.Name
	}
	return ""
}

func unwrap(expr ast.Expr) ast.Expr {
	for {
		switch typed := expr.(type) {
		case *ast.ParenExpr:
			expr = typed.X
		case *ast.StarExpr:
			expr = typed.X
		case *ast.UnaryExpr:
			if typed.Op == token.AND {
				expr = typed.X
				continue
			}
			return expr
		case *ast.IndexExpr:
			expr = typed.X
		case *ast.IndexListExpr:
			expr = typed.X
		default:
			return expr
		}
	}
}

func (w *world) bindingFor(ident *ast.Ident, sc *scope, pkg *packageInfo) (binding, bool) {
	if sc != nil {
		if value, ok := sc.lookup(ident.Name); ok {
			return value, true
		}
	}
	value, ok := pkg.vars[ident.Name]
	return value, ok
}

// typeExprOf returns the type expression an expression evaluates to, with the
// file whose imports name its qualifier.
func (w *world) typeExprOf(expr ast.Expr, index int, sc *scope, fc *fileContext, pkg *packageInfo, depth int) (ast.Expr, *fileContext) {
	if depth > 12 || expr == nil {
		return nil, nil
	}
	switch typed := unwrap(expr).(type) {
	case *ast.CompositeLit:
		return typed.Type, fc
	case *ast.Ident:
		value, ok := w.bindingFor(typed, sc, pkg)
		if !ok {
			return nil, nil
		}
		if value.typeExpr != nil {
			return value.typeExpr, value.file
		}
		if value.expr != nil {
			return w.typeExprOf(value.expr, value.index, sc, value.file, pkg, depth+1)
		}
		return nil, nil
	case *ast.CallExpr:
		def, ok := w.resolveCallDef(typed, sc, fc, pkg, depth)
		if !ok || def.node.Type.Results == nil {
			return nil, nil
		}
		if index >= len(def.node.Type.Results.List) {
			return nil, nil
		}
		return def.node.Type.Results.List[index].Type, def.file
	case *ast.TypeAssertExpr:
		return typed.Type, fc
	}
	return nil, nil
}

func (w *world) resolveCallDef(call *ast.CallExpr, sc *scope, fc *fileContext, pkg *packageInfo, depth int) (funcDef, bool) {
	if depth > 12 {
		return funcDef{}, false
	}
	switch fun := unwrap(call.Fun).(type) {
	case *ast.Ident:
		def, ok := pkg.funcs[fun.Name]
		return def, ok
	case *ast.SelectorExpr:
		if alias, ok := unwrap(fun.X).(*ast.Ident); ok {
			if importPath, exists := fc.imports[alias.Name]; exists {
				target := w.packageAt(importPath)
				def, ok := target.funcs[fun.Sel.Name]
				return def, ok
			}
		}
		receiverType, receiverFile := w.typeExprOf(fun.X, 0, sc, fc, pkg, depth+1)
		if receiverType != nil {
			ownerPath, ownerType, ok := w.resolveTypeRef(receiverType, receiverFile)
			if ok {
				owner := w.packageAt(ownerPath)
				def, exists := owner.methods[ownerType+"."+fun.Sel.Name]
				return def, exists
			}
		}
	}
	return funcDef{}, false
}

// resolveTypeRef maps a type expression to its defining package path and name.
func (w *world) resolveTypeRef(expr ast.Expr, fc *fileContext) (string, string, bool) {
	if expr == nil || fc == nil {
		return "", "", false
	}
	expr = unwrap(expr)
	if selector, ok := expr.(*ast.SelectorExpr); ok {
		if alias, isIdent := unwrap(selector.X).(*ast.Ident); isIdent {
			if path, exists := fc.imports[alias.Name]; exists {
				return path, selector.Sel.Name, true
			}
		}
	}
	if ident, ok := expr.(*ast.Ident); ok {
		if _, exists := w.packageAt(fc.pkgPath).types[ident.Name]; exists {
			return fc.pkgPath, ident.Name, true
		}
	}
	return "", "", false
}

func qualifiedName(expr ast.Expr, fc *fileContext) string {
	expr = unwrap(expr)
	if selector, ok := expr.(*ast.SelectorExpr); ok {
		if alias, isIdent := unwrap(selector.X).(*ast.Ident); isIdent {
			return alias.Name + "." + selector.Sel.Name
		}
	}
	if ident, ok := expr.(*ast.Ident); ok {
		return ident.Name
	}
	return ""
}

type refs struct {
	apps      []string
	postgres  []string
	seenApps  map[string]bool
	seenStore map[string]bool
}

func (r *refs) addApp(name string) {
	if !r.seenApps[name] {
		r.seenApps[name] = true
		r.apps = append(r.apps, name)
	}
}

func (r *refs) addStore(path string) {
	if !r.seenStore[path] {
		r.seenStore[path] = true
		r.postgres = append(r.postgres, path)
	}
}

func (w *world) classifyImport(path string, r *refs) {
	if strings.HasPrefix(path, modulePath+"internal/application/") {
		r.addApp(strings.TrimPrefix(path, modulePath+"internal/application/"))
	}
	if strings.HasPrefix(path, modulePath+"internal/adapters/postgres/") {
		r.addStore(path)
	}
}

func (w *world) collectRefs(expr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, depth int, seen map[string]bool, r *refs) {
	if expr == nil || depth > 10 {
		return
	}
	switch typed := unwrap(expr).(type) {
	case *ast.SelectorExpr:
		if alias, ok := unwrap(typed.X).(*ast.Ident); ok {
			if path, exists := fc.imports[alias.Name]; exists {
				w.classifyImport(path, r)
				return
			}
		}
		w.collectRefs(typed.X, sc, fc, pkg, depth+1, seen, r)
	case *ast.Ident:
		if seen[typed.Name] {
			return
		}
		seen[typed.Name] = true
		value, ok := w.bindingFor(typed, sc, pkg)
		if !ok {
			return
		}
		if value.typeExpr != nil {
			if path, _, ok := w.resolveTypeRef(value.typeExpr, value.file); ok {
				w.classifyImport(path, r)
			}
			w.collectRefs(value.typeExpr, sc, value.file, pkg, depth+1, seen, r)
		}
		if value.expr != nil {
			w.collectRefs(value.expr, sc, value.file, pkg, depth+1, seen, r)
		}
	case *ast.CompositeLit:
		if path, _, ok := w.resolveTypeRef(typed.Type, fc); ok {
			w.classifyImport(path, r)
		}
		w.collectRefs(typed.Type, sc, fc, pkg, depth+1, seen, r)
		for _, element := range typed.Elts {
			if pair, ok := element.(*ast.KeyValueExpr); ok {
				w.collectRefs(pair.Value, sc, fc, pkg, depth+1, seen, r)
				continue
			}
			w.collectRefs(element, sc, fc, pkg, depth+1, seen, r)
		}
	case *ast.CallExpr:
		if path, _, ok := w.callPackage(typed, sc, fc, pkg, depth); ok {
			w.classifyImport(path, r)
		}
		if def, ok := w.resolveCallDef(typed, sc, fc, pkg, depth); ok && def.node.Type.Results != nil && len(def.node.Type.Results.List) > 0 {
			if path, _, resolved := w.resolveTypeRef(def.node.Type.Results.List[0].Type, def.file); resolved {
				w.classifyImport(path, r)
			}
		}
		for _, arg := range typed.Args {
			w.collectRefs(arg, sc, fc, pkg, depth+1, seen, r)
		}
	case *ast.UnaryExpr:
		w.collectRefs(typed.X, sc, fc, pkg, depth+1, seen, r)
	case *ast.BinaryExpr:
		w.collectRefs(typed.X, sc, fc, pkg, depth+1, seen, r)
		w.collectRefs(typed.Y, sc, fc, pkg, depth+1, seen, r)
	case *ast.ArrayType:
		w.collectRefs(typed.Elt, sc, fc, pkg, depth+1, seen, r)
	case *ast.MapType:
		w.collectRefs(typed.Key, sc, fc, pkg, depth+1, seen, r)
		w.collectRefs(typed.Value, sc, fc, pkg, depth+1, seen, r)
	}
}

func (w *world) callPackage(call *ast.CallExpr, sc *scope, fc *fileContext, pkg *packageInfo, depth int) (string, string, bool) {
	selector, ok := unwrap(call.Fun).(*ast.SelectorExpr)
	if !ok {
		return "", "", false
	}
	alias, ok := unwrap(selector.X).(*ast.Ident)
	if !ok {
		return "", "", false
	}
	path, exists := fc.imports[alias.Name]
	if !exists {
		return "", "", false
	}
	return path, selector.Sel.Name, true
}

type registration struct {
	MID               int      `json:"mid"`
	DispatcherType    string   `json:"dispatcher_type"`
	DispatcherPackage string   `json:"dispatcher_package"`
	DispatcherFile    string   `json:"dispatcher_file"`
	HandlerFile       string   `json:"handler_file"`
	HandlerLine       int      `json:"handler_line"`
	RegistrationFile  string   `json:"registration_file"`
	RegistrationLine  int      `json:"registration_line"`
	WiringFile        string   `json:"wiring_file"`
	ConstructionFile  string   `json:"construction_file"`
	Owner             string   `json:"owner"`
	Reason            string   `json:"reason,omitempty"`
	Fallback          bool     `json:"fallback,omitempty"`
	Wrappers          []string `json:"wrappers"`
	Stores            []string `json:"stores"`
}

type push struct {
	Kind       string   `json:"kind"`
	MID        int64    `json:"mid,omitempty"`
	ParentMID  int64    `json:"parent_mid,omitempty"`
	Namespace  string   `json:"namespace,omitempty"`
	NoticeType int64    `json:"notice_type,omitempty"`
	Roles      []string `json:"roles"`
	File       string   `json:"file"`
	Line       int      `json:"line"`
	Apps       []string `json:"app_imports"`
}

type output struct {
	Registrations []registration `json:"registrations"`
	Pushes        []push         `json:"pushes"`
	Typed         typedOutput    `json:"typed"`
	MIDClasses    []midClass     `json:"mid_classes"`
}

type walker struct {
	w        *world
	output   *output
	fallback bool
}

func (v *walker) walkPackage(pkg *packageInfo) {
	for _, fc := range pkg.files {
		for _, decl := range fc.ast.Decls {
			fn, ok := decl.(*ast.FuncDecl)
			if !ok || fn.Body == nil {
				continue
			}
			v.walkFunc(fn, fc, pkg, nil, "")
		}
	}
}

func (v *walker) walkFunc(fn *ast.FuncDecl, fc *fileContext, pkg *packageInfo, parent *scope, wiringFile string) {
	sc := newScope(parent)
	if fn.Type.Params != nil {
		for _, field := range fn.Type.Params.List {
			for _, name := range field.Names {
				sc.values[name.Name] = binding{typeExpr: field.Type, file: fc}
			}
		}
	}
	if fn.Recv != nil {
		for _, field := range fn.Recv.List {
			for _, name := range field.Names {
				sc.values[name.Name] = binding{typeExpr: field.Type, file: fc}
			}
		}
	}
	v.walkStmt(fn.Body, sc, fc, pkg, wiringFile)
}

func (v *walker) walkStmt(stmt ast.Stmt, sc *scope, fc *fileContext, pkg *packageInfo, wiringFile string) {
	if stmt == nil {
		return
	}
	switch typed := stmt.(type) {
	case *ast.BlockStmt:
		child := newScope(sc)
		for _, inner := range typed.List {
			v.walkStmt(inner, child, fc, pkg, wiringFile)
		}
	case *ast.AssignStmt:
		v.recordAssignment(typed, sc, fc, pkg)
		for _, rhs := range typed.Rhs {
			if call, ok := unwrap(rhs).(*ast.CallExpr); ok {
				v.maybeRegister(call, sc, fc, pkg, wiringFile)
			}
		}
	case *ast.DeclStmt:
		if gen, ok := typed.Decl.(*ast.GenDecl); ok {
			for _, raw := range gen.Specs {
				spec, ok := raw.(*ast.ValueSpec)
				if !ok {
					continue
				}
				for index, name := range spec.Names {
					value := binding{file: fc, typeExpr: spec.Type}
					if len(spec.Values) == 1 {
						value.expr = spec.Values[0]
						value.index = index
					} else if index < len(spec.Values) {
						value.expr = spec.Values[index]
					}
					sc.values[name.Name] = value
				}
			}
		}
	case *ast.ExprStmt:
		if call, ok := unwrap(typed.X).(*ast.CallExpr); ok {
			v.maybeRegister(call, sc, fc, pkg, wiringFile)
		}
	case *ast.IfStmt:
		child := newScope(sc)
		if typed.Init != nil {
			v.walkStmt(typed.Init, child, fc, pkg, wiringFile)
		}
		v.walkStmt(typed.Body, child, fc, pkg, wiringFile)
		if typed.Else != nil {
			v.walkStmt(typed.Else, child, fc, pkg, wiringFile)
		}
	case *ast.ForStmt:
		child := newScope(sc)
		if typed.Init != nil {
			v.walkStmt(typed.Init, child, fc, pkg, wiringFile)
		}
		if name, values, ok := v.classicLoopValues(typed, child, fc, pkg); ok {
			child.values[name] = binding{midList: values, file: fc}
		}
		v.walkStmt(typed.Body, child, fc, pkg, wiringFile)
	case *ast.RangeStmt:
		v.walkRange(typed, sc, fc, pkg, wiringFile)
	case *ast.SwitchStmt:
		child := newScope(sc)
		if typed.Init != nil {
			v.walkStmt(typed.Init, child, fc, pkg, wiringFile)
		}
		v.walkStmt(typed.Body, child, fc, pkg, wiringFile)
	case *ast.CaseClause:
		for _, inner := range typed.Body {
			v.walkStmt(inner, sc, fc, pkg, wiringFile)
		}
	case *ast.ReturnStmt:
		for _, result := range typed.Results {
			if call, ok := unwrap(result).(*ast.CallExpr); ok {
				v.maybeRegister(call, sc, fc, pkg, wiringFile)
			}
		}
	}
}

// classicLoopValues recognises `for mid := uint16(N); mid <= M; mid++`.
func (v *walker) classicLoopValues(stmt *ast.ForStmt, sc *scope, fc *fileContext, pkg *packageInfo) (string, []int, bool) {
	init, ok := stmt.Init.(*ast.AssignStmt)
	if !ok || len(init.Lhs) != 1 || len(init.Rhs) != 1 {
		return "", nil, false
	}
	name, isIdent := unwrap(init.Lhs[0]).(*ast.Ident)
	if !isIdent {
		return "", nil, false
	}
	start, ok := v.w.evalInt(init.Rhs[0], fc, pkg, 0)
	if !ok {
		return "", nil, false
	}
	cond, isCond := stmt.Cond.(*ast.BinaryExpr)
	if !isCond {
		return "", nil, false
	}
	condName, isCondIdent := unwrap(cond.X).(*ast.Ident)
	if !isCondIdent || condName.Name != name.Name {
		return "", nil, false
	}
	end, ok := v.w.evalInt(cond.Y, fc, pkg, 0)
	if !ok {
		return "", nil, false
	}
	if cond.Op != token.LEQ && cond.Op != token.LSS {
		return "", nil, false
	}
	if cond.Op == token.LSS {
		end--
	}
	post, isPost := stmt.Post.(*ast.IncDecStmt)
	if !isPost || post.Tok != token.INC {
		return "", nil, false
	}
	postName, isPostIdent := unwrap(post.X).(*ast.Ident)
	if !isPostIdent || postName.Name != name.Name {
		return "", nil, false
	}
	if end < start || end-start > 10000 {
		return "", nil, false
	}
	values := []int{}
	for current := start; current <= end; current++ {
		values = append(values, int(current))
	}
	return name.Name, values, true
}

func (v *walker) recordAssignment(assign *ast.AssignStmt, sc *scope, fc *fileContext, pkg *packageInfo) {
	for index, lhs := range assign.Lhs {
		ident, ok := unwrap(lhs).(*ast.Ident)
		if !ok {
			continue
		}
		value := binding{file: fc}
		if len(assign.Rhs) == 1 && len(assign.Lhs) > 1 {
			value.expr = assign.Rhs[0]
			value.index = index
		} else if index < len(assign.Rhs) {
			value.expr = assign.Rhs[index]
		}
		sc.values[ident.Name] = value
	}
}

func (v *walker) walkRange(stmt *ast.RangeStmt, sc *scope, fc *fileContext, pkg *packageInfo, wiringFile string) {
	values, source, ok := v.w.evalMids(stmt.X, sc, fc, pkg, 0)
	if !ok {
		return
	}
	child := newScope(sc)
	if ident, isIdent := stmt.Value.(*ast.Ident); isIdent {
		child.values[ident.Name] = binding{midList: values, file: fc}
	}
	if ident, isIdent := stmt.Key.(*ast.Ident); isIdent {
		child.values[ident.Name] = binding{midList: values, file: fc}
	}
	previous := v.fallback
	v.fallback = v.fallback || source == "InactiveModeMIDs"
	v.walkStmt(stmt.Body, child, fc, pkg, wiringFile)
	v.fallback = previous
}

func (v *walker) maybeRegister(call *ast.CallExpr, sc *scope, fc *fileContext, pkg *packageInfo, wiringFile string) {
	if path, name, ok := v.w.callPackage(call, sc, fc, pkg, 0); ok && path == modulePath+"internal/adapters/stockruntime" && strings.HasPrefix(name, "Register") {
		v.walkRegisterHelper(path, name, call, sc, fc, pkg)
		return
	}
	midExpr, dispatcherExpr, ok := registrationArguments(call)
	if !ok {
		return
	}
	values, _, resolved := v.w.evalMids(midExpr, sc, fc, pkg, 0)
	if !resolved {
		return
	}
	for _, mid := range values {
		v.emit(mid, dispatcherExpr, sc, fc, pkg, fc.rel, v.w.fset.Position(call.Pos()).Line, wiringFile)
	}
}

func registrationArguments(call *ast.CallExpr) (ast.Expr, ast.Expr, bool) {
	if len(call.Args) < 2 {
		return nil, nil, false
	}
	switch fun := unwrap(call.Fun).(type) {
	case *ast.Ident:
		if fun.Name == "mustRegister" || fun.Name == "Register" {
			return call.Args[0], call.Args[1], true
		}
	case *ast.SelectorExpr:
		if fun.Sel.Name == "Register" {
			return call.Args[0], call.Args[1], true
		}
	}
	return nil, nil, false
}

func (v *walker) walkRegisterHelper(path, name string, call *ast.CallExpr, sc *scope, fc *fileContext, pkg *packageInfo) {
	helperPkg := v.w.packageAt(path)
	def, ok := helperPkg.funcs[name]
	if !ok || def.node.Body == nil || len(call.Args) < 2 {
		return
	}
	helperScope := newScope(sc)
	if def.node.Type.Params != nil && len(def.node.Type.Params.List) >= 2 {
		paramNames := def.node.Type.Params.List[1].Names
		if len(paramNames) > 0 {
			helperScope.values[paramNames[0].Name] = binding{expr: call.Args[1], file: fc}
		}
	}
	for _, param := range def.node.Type.Params.List {
		for _, paramName := range param.Names {
			if _, exists := helperScope.values[paramName.Name]; exists {
				continue
			}
			helperScope.values[paramName.Name] = binding{typeExpr: param.Type, file: def.file}
		}
	}
	v.walkStmt(def.node.Body, helperScope, def.file, helperPkg, fc.rel)
}

func (v *walker) emit(mid int, dispatcherExpr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, registrationFile string, line int, wiringFile string) {
	owner, dispatcherType, dispatcherFile, constructionFile, stores, reason := v.w.attribute(dispatcherExpr, sc, fc, pkg, registrationFile)
	dispatcherPackage, handlerFile, handlerLine := v.w.handlerOf(dispatcherType, dispatcherFile)
	wrappers := v.w.wrappersOf(dispatcherExpr, sc, fc, pkg, 0)
	if wrappers == nil {
		wrappers = []string{}
	}
	sort.Strings(wrappers)
	fallback := v.fallback
	if fallback {
		owner = ""
		reason = "inactive fallback registration"
	}
	if wiringFile == "" {
		wiringFile = registrationFile
	}
	if stores == nil {
		stores = []string{}
	}
	sort.Strings(stores)
	v.output.Registrations = append(v.output.Registrations, registration{
		MID: mid, DispatcherType: dispatcherType, DispatcherPackage: dispatcherPackage,
		DispatcherFile: dispatcherFile, HandlerFile: handlerFile, HandlerLine: handlerLine,
		RegistrationFile: registrationFile, RegistrationLine: line, WiringFile: wiringFile,
		ConstructionFile: constructionFile, Owner: owner, Reason: reason, Fallback: fallback, Wrappers: wrappers, Stores: stores,
	})
}

func (w *world) handlerOf(dispatcherType, dispatcherFile string) (string, string, int) {
	if dispatcherType == "" || dispatcherFile == "" {
		return "", "", 0
	}
	for _, pkg := range w.packages {
		for _, fc := range pkg.files {
			if fc.rel != dispatcherFile {
				continue
			}
			def, ok := pkg.methods[dispatcherType+".Dispatch"]
			if !ok {
				return fc.pkgPath, "", 0
			}
			return fc.pkgPath, def.file.rel, w.fset.Position(def.node.Pos()).Line
		}
	}
	return "", "", 0
}

func (w *world) attribute(dispatcherExpr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, registrationFile string) (string, string, string, string, []string, string) {
	literal, literalFile := w.findDispatcherLiteral(dispatcherExpr, sc, fc, pkg, 0)
	dispatcherType := ""
	dispatcherFile := ""
	var literalFields []*ast.KeyValueExpr
	if literal != nil {
		if path, name, ok := w.resolveTypeRef(literal.Type, literalFile); ok {
			dispatcherType = name
			if file, exists := w.packageAt(path).types[name]; exists {
				dispatcherFile = file.rel
			}
		}
		for _, element := range literal.Elts {
			if pair, isPair := element.(*ast.KeyValueExpr); isPair {
				literalFields = append(literalFields, pair)
			}
		}
	}
	if dispatcherType == "" {
		if typeExpr, typeFile := w.typeExprOf(dispatcherExpr, 0, sc, fc, pkg, 0); typeExpr != nil {
			if path, name, ok := w.resolveTypeRef(typeExpr, typeFile); ok && path == modulePath+"internal/adapters/stockruntime" {
				dispatcherType = name
				if file, exists := w.packageAt(path).types[name]; exists {
					dispatcherFile = file.rel
				}
			}
		}
	}
	constructionFile := registrationFile
	if literal != nil && literalFile != nil {
		constructionFile = literalFile.rel
	} else if call, found := w.constructionCall(dispatcherExpr, sc, fc, pkg, 0); found {
		if def, exists := w.resolveCallDef(call, sc, fc, pkg, 0); exists {
			constructionFile = def.file.rel
		}
	}
	owner := ""
	reason := ""
	var storeRefs refs
	storeRefs.seenApps = map[string]bool{}
	storeRefs.seenStore = map[string]bool{}
	if literal != nil {
		for _, field := range literalFields {
			key, ok := field.Key.(*ast.Ident)
			if !ok || key.Name != "Service" {
				continue
			}
			fieldRefs := w.refsOf(field.Value, sc, literalFile, pkg)
			if len(fieldRefs.apps) > 0 {
				owner = fieldRefs.apps[0]
				for _, app := range fieldRefs.apps {
					if strings.EqualFold(key.Name, app) {
						owner = app
						break
					}
				}
			}
		}
		if owner == "" {
			fileApps := []string{}
			for _, app := range w.appImportsOfFile(dispatcherFile) {
				if app != "realtimeauth" {
					fileApps = append(fileApps, app)
				}
			}
			for _, field := range literalFields {
				key, ok := field.Key.(*ast.Ident)
				if !ok {
					continue
				}
				for _, app := range fileApps {
					if strings.EqualFold(key.Name, app) {
						owner = app
						break
					}
				}
				if owner != "" {
					break
				}
			}
		}
		if owner == "" {
			for _, field := range literalFields {
				key, ok := field.Key.(*ast.Ident)
				if !ok || key.Name == "Authority" {
					continue
				}
				fieldRefs := w.refsOf(field.Value, sc, literalFile, pkg)
				if len(fieldRefs.apps) == 0 {
					continue
				}
				owner = fieldRefs.apps[0]
				for _, app := range fieldRefs.apps {
					if strings.EqualFold(key.Name, app) {
						owner = app
						break
					}
				}
				break
			}
		}
		seen := map[string]bool{}
		var serviceValue ast.Expr
		for _, field := range literalFields {
			if key, ok := field.Key.(*ast.Ident); ok && key.Name == "Service" {
				serviceValue = field.Value
			}
		}
		if serviceValue == nil {
			w.collectRefs(literal, sc, literalFile, pkg, 0, seen, &storeRefs)
		} else if call, isCall := w.constructionCall(serviceValue, sc, literalFile, pkg, 0); isCall {
			if def, exists := w.resolveCallDef(call, sc, literalFile, pkg, 0); exists {
				constructionFile = def.file.rel
				storeRefs.postgres = w.postgresImportsOfFile(constructionFile)
			}
		}
		if serviceValue != nil && len(storeRefs.postgres) == 0 {
			w.collectRefs(serviceValue, sc, literalFile, pkg, 0, seen, &storeRefs)
		}
	}
	if owner == "" && dispatcherFile != "" {
		apps := w.appImportsOfFile(dispatcherFile)
		filtered := []string{}
		for _, app := range apps {
			if app != "realtimeauth" {
				filtered = append(filtered, app)
			}
		}
		if len(filtered) == 1 {
			owner = filtered[0]
		} else if len(filtered) > 1 && literal != nil {
			for _, field := range literalFields {
				key, ok := field.Key.(*ast.Ident)
				if !ok {
					continue
				}
				for _, app := range filtered {
					if strings.EqualFold(key.Name, app) {
						owner = app
						break
					}
				}
				if owner != "" {
					break
				}
			}
		} else if len(filtered) == 0 {
			for _, app := range apps {
				if app == "realtimeauth" {
					owner = app
				}
			}
		}
	}
	if owner == "" {
		reason = "no application package resolves from the dispatcher or its wiring"
		if dispatcherType == "" {
			reason = "dispatcher type not resolved"
		}
	}
	if literal == nil {
		seen := map[string]bool{}
		w.collectRefs(dispatcherExpr, sc, fc, pkg, 0, seen, &storeRefs)
		if len(storeRefs.postgres) == 0 {
			storeRefs.postgres = w.postgresImportsOfFile(constructionFile)
		}
		if len(storeRefs.postgres) == 0 {
			storeRefs.postgres = w.postgresImportsOfFile(registrationFile)
		}
	}
	sort.Strings(storeRefs.postgres)
	return owner, dispatcherType, dispatcherFile, constructionFile, storeRefs.postgres, reason
}

func (w *world) refsOf(expr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo) refs {
	r := refs{seenApps: map[string]bool{}, seenStore: map[string]bool{}}
	seen := map[string]bool{}
	w.collectRefs(expr, sc, fc, pkg, 0, seen, &r)
	return r
}

func (w *world) wrappersOf(expr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, depth int) []string {
	if expr == nil || depth > 8 {
		return nil
	}
	switch typed := unwrap(expr).(type) {
	case *ast.CallExpr:
		name := ""
		switch fun := unwrap(typed.Fun).(type) {
		case *ast.Ident:
			name = fun.Name
		case *ast.SelectorExpr:
			name = fun.Sel.Name
		}
		if name != "" {
			for _, argument := range typed.Args {
				if literal, _ := w.findDispatcherLiteral(argument, sc, fc, pkg, depth+1); literal != nil {
					return []string{name}
				}
			}
		}
	case *ast.Ident:
		value, ok := w.bindingFor(typed, sc, pkg)
		if ok && value.expr != nil {
			return w.wrappersOf(value.expr, sc, value.file, pkg, depth+1)
		}
	}
	return nil
}

func (w *world) constructionCall(expr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, depth int) (*ast.CallExpr, bool) {
	if expr == nil || depth > 8 {
		return nil, false
	}
	switch typed := unwrap(expr).(type) {
	case *ast.CallExpr:
		return typed, true
	case *ast.Ident:
		value, ok := w.bindingFor(typed, sc, pkg)
		if !ok || value.expr == nil {
			return nil, false
		}
		return w.constructionCall(value.expr, sc, value.file, pkg, depth+1)
	}
	return nil, false
}

func (w *world) findDispatcherLiteral(expr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, depth int) (*ast.CompositeLit, *fileContext) {
	if expr == nil || depth > 10 {
		return nil, nil
	}
	switch typed := unwrap(expr).(type) {
	case *ast.CompositeLit:
		if path, name, ok := w.resolveTypeRef(typed.Type, fc); ok && path == modulePath+"internal/adapters/stockruntime" && strings.HasSuffix(name, "Dispatcher") {
			return typed, fc
		}
		for _, element := range typed.Elts {
			if pair, ok := element.(*ast.KeyValueExpr); ok {
				if found, foundFile := w.findDispatcherLiteral(pair.Value, sc, fc, pkg, depth+1); found != nil {
					return found, foundFile
				}
				continue
			}
			if found, foundFile := w.findDispatcherLiteral(element, sc, fc, pkg, depth+1); found != nil {
				return found, foundFile
			}
		}
	case *ast.Ident:
		value, ok := w.bindingFor(typed, sc, pkg)
		if !ok {
			return nil, nil
		}
		if value.expr != nil {
			return w.findDispatcherLiteral(value.expr, sc, value.file, pkg, depth+1)
		}
	case *ast.CallExpr:
		for _, arg := range typed.Args {
			if found, foundFile := w.findDispatcherLiteral(arg, sc, fc, pkg, depth+1); found != nil {
				return found, foundFile
			}
		}
	}
	return nil, nil
}

func (w *world) appImportsOfFile(rel string) []string {
	for _, pkg := range w.packages {
		for _, fc := range pkg.files {
			if fc.rel != rel {
				continue
			}
			apps := []string{}
			for _, importPath := range fc.imports {
				if strings.HasPrefix(importPath, modulePath+"internal/application/") {
					apps = append(apps, strings.TrimPrefix(importPath, modulePath+"internal/application/"))
				}
			}
			sort.Strings(apps)
			return apps
		}
	}
	return nil
}

func (w *world) postgresImportsOfFile(rel string) []string {
	for _, pkg := range w.packages {
		for _, fc := range pkg.files {
			if fc.rel != rel {
				continue
			}
			stores := []string{}
			for _, importPath := range fc.imports {
				if strings.HasPrefix(importPath, modulePath+"internal/adapters/postgres/") {
					stores = append(stores, importPath)
				}
			}
			sort.Strings(stores)
			return stores
		}
	}
	return nil
}

// evalMids resolves the integer list behind a range expression:
// []uint16 literals, package variables, or classic uint16 loops.
func (w *world) evalMids(expr ast.Expr, sc *scope, fc *fileContext, pkg *packageInfo, depth int) ([]int, string, bool) {
	if expr == nil || depth > 10 {
		return nil, "", false
	}
	switch typed := unwrap(expr).(type) {
	case *ast.BasicLit:
		value, ok := w.evalInt(typed, fc, pkg, 0)
		if !ok {
			return nil, "", false
		}
		return []int{int(value)}, "", true
	case *ast.CompositeLit:
		values := []int{}
		for _, element := range typed.Elts {
			value, ok := w.evalInt(element, fc, pkg, 0)
			if !ok {
				return nil, "", false
			}
			values = append(values, int(value))
		}
		return values, "", true
	case *ast.Ident:
		value, ok := w.bindingFor(typed, sc, pkg)
		if !ok {
			return nil, "", false
		}
		if len(value.midList) > 0 {
			return value.midList, "", true
		}
		if value.expr != nil {
			source := ""
			if ident, isIdent := unwrap(value.expr).(*ast.Ident); isIdent {
				source = ident.Name
			}
			if selector, isSelector := unwrap(value.expr).(*ast.SelectorExpr); isSelector {
				source = selector.Sel.Name
			}
			values, _, ok := w.evalMids(value.expr, sc, value.file, pkg, depth+1)
			return values, source, ok
		}
		return nil, "", false
	case *ast.SelectorExpr:
		alias, ok := unwrap(typed.X).(*ast.Ident)
		if !ok {
			return nil, "", false
		}
		importPath, exists := fc.imports[alias.Name]
		if !exists {
			return nil, "", false
		}
		target := w.packageAt(importPath)
		value, ok := target.vars[typed.Sel.Name]
		if !ok || value.expr == nil {
			return nil, "", false
		}
		values, _, ok := w.evalMids(value.expr, nil, value.file, target, depth+1)
		return values, typed.Sel.Name, ok
	}
	return nil, "", false
}

func (w *world) evalInt(expr ast.Expr, fc *fileContext, pkg *packageInfo, depth int) (int64, bool) {
	if expr == nil || depth > 12 {
		return 0, false
	}
	switch typed := unwrap(expr).(type) {
	case *ast.BasicLit:
		if typed.Kind != token.INT {
			return 0, false
		}
		value, err := strconv.ParseInt(strings.TrimRight(typed.Value, "uU"), 10, 64)
		return value, err == nil
	case *ast.Ident:
		value, ok := pkg.vars[typed.Name]
		if !ok || value.expr == nil {
			return 0, false
		}
		return w.evalInt(value.expr, value.file, pkg, depth+1)
	case *ast.SelectorExpr:
		alias, ok := unwrap(typed.X).(*ast.Ident)
		if !ok {
			return 0, false
		}
		importPath, exists := fc.imports[alias.Name]
		if !exists {
			return 0, false
		}
		target := w.packageAt(importPath)
		value, ok := target.vars[typed.Sel.Name]
		if !ok || value.expr == nil {
			return 0, false
		}
		return w.evalInt(value.expr, value.file, target, depth+1)
	case *ast.CallExpr:
		if len(typed.Args) == 1 {
			return w.evalInt(typed.Args[0], fc, pkg, depth+1)
		}
	case *ast.UnaryExpr:
		if typed.Op == token.SUB {
			value, ok := w.evalInt(typed.X, fc, pkg, depth+1)
			return -value, ok
		}
	}
	return 0, false
}

func (w *world) collectPushes() []push {
	result := []push{}
	files := []*fileContext{}
	for _, path := range []string{modulePath + "internal/adapters/stockruntime", modulePath + "internal/protocol/realtime"} {
		pkg := w.packageAt(path)
		files = append(files, pkg.files...)
	}
	for _, fc := range files {
		ast.Inspect(fc.ast, func(node ast.Node) bool {
			literal, ok := node.(*ast.CompositeLit)
			if !ok {
				return true
			}
			fields := map[string]ast.Expr{}
			for _, element := range literal.Elts {
				pair, isPair := element.(*ast.KeyValueExpr)
				if !isPair {
					continue
				}
				key, isIdent := pair.Key.(*ast.Ident)
				if isIdent {
					fields[key.Name] = pair.Value
				}
			}
			// Registration literals inside []Registration{...} elide their type,
			// so classify by the field keys the source uses.
			name := ""
			switch {
			case fields["ParentMID"] != nil || fields["NoticeType"] != nil:
				name = "NoticeRegistration"
			case fields["MID"] != nil && fields["Roles"] != nil:
				name = "DirectRegistration"
			default:
				return true
			}
			apps := []string{}
			for _, importPath := range fc.imports {
				if strings.HasPrefix(importPath, modulePath+"internal/application/") {
					apps = append(apps, strings.TrimPrefix(importPath, modulePath+"internal/application/"))
				}
			}
			sort.Strings(apps)
			filtered := []string{}
			for _, app := range apps {
				if app != "realtimeauth" {
					filtered = append(filtered, app)
				}
			}
			entry := push{Roles: []string{}, File: fc.rel, Line: w.fset.Position(literal.Pos()).Line, Apps: filtered}
			if name == "DirectRegistration" {
				mid, midOK := w.evalInt(fields["MID"], fc, w.packageAt(fc.pkgPath), 0)
				if !midOK {
					return true
				}
				entry.Kind = "direct"
				entry.MID = mid
				entry.Roles = identList(fields["Roles"])
			} else {
				parent, parentOK := w.evalInt(fields["ParentMID"], fc, w.packageAt(fc.pkgPath), 0)
				if !parentOK {
					return true
				}
				entry.Kind = "notice"
				entry.ParentMID = parent
				entry.Namespace = qualifiedName(fields["Namespace"], fc)
				if noticeType, ok := w.evalInt(fields["NoticeType"], fc, w.packageAt(fc.pkgPath), 0); ok {
					entry.NoticeType = noticeType
				}
				entry.Roles = identList(fields["Roles"])
			}
			result = append(result, entry)
			return true
		})
	}
	return result
}

func identList(expr ast.Expr) []string {
	values := []string{}
	if expr == nil {
		return values
	}
	ast.Inspect(expr, func(node ast.Node) bool {
		selector, ok := node.(*ast.SelectorExpr)
		if ok {
			values = append(values, selector.Sel.Name)
			return false
		}
		ident, ok := node.(*ast.Ident)
		if ok && ident.Name != "Role" && ident.Name != "Roles" {
			values = append(values, ident.Name)
		}
		return true
	})
	sort.Strings(values)
	return values
}

func main() {
	traceArgument := flag.Int("trace", -1, "print the live call graph of a registered MID")
	flag.Parse()
	root, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	w := &world{fset: token.NewFileSet(), root: root, packages: map[string]*packageInfo{}}
	commandPkg := w.packageAt(modulePath + "cmd/gxb-api")
	out := &output{Registrations: []registration{}, Pushes: []push{}}
	walker := &walker{w: w, output: out}
	walker.walkPackage(commandPkg)
	out.Pushes = w.collectPushes()
	sort.Slice(out.Registrations, func(i, j int) bool {
		if out.Registrations[i].MID != out.Registrations[j].MID {
			return out.Registrations[i].MID < out.Registrations[j].MID
		}
		if out.Registrations[i].RegistrationFile != out.Registrations[j].RegistrationFile {
			return out.Registrations[i].RegistrationFile < out.Registrations[j].RegistrationFile
		}
		return out.Registrations[i].RegistrationLine < out.Registrations[j].RegistrationLine
	})
	sort.Slice(out.Pushes, func(i, j int) bool {
		if out.Pushes[i].File != out.Pushes[j].File {
			return out.Pushes[i].File < out.Pushes[j].File
		}
		if out.Pushes[i].Line != out.Pushes[j].Line {
			return out.Pushes[i].Line < out.Pushes[j].Line
		}
		return out.Pushes[i].Kind < out.Pushes[j].Kind
	})
	if *traceArgument >= 0 {
		typedWorld := newTypedWorld(root)
		if err := typedWorld.load(); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		text, traceErr := traceMID(out, typedWorld, *traceArgument)
		if traceErr != nil {
			fmt.Fprintln(os.Stderr, traceErr)
			os.Exit(1)
		}
		fmt.Print(text)
		return
	}
	typedWorld := newTypedWorld(root)
	if err := typedWorld.load(); err != nil {
		out.Typed = typedOutput{Gaps: []string{err.Error()}}
	} else {
		out.Typed = collectTyped(typedWorld)
		out.MIDClasses = collectMIDClasses(out, typedWorld)
	}
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", " ")
	if err := encoder.Encode(out); err != nil {
		panic(err)
	}
}
