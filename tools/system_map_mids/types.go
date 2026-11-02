package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"go/ast"
	"go/constant"
	"go/importer"
	"go/parser"
	"go/token"
	"go/types"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

const implementerThreshold = 6

type listedPackage struct {
	ImportPath      string
	Name            string
	Dir             string
	GoFiles         []string
	CompiledGoFiles []string
	Export          string
	Standard        bool
}

type typedEdge struct {
	From      string `json:"from"`
	To        string `json:"to"`
	Method    string `json:"method"`
	ViaPort   bool   `json:"via_port"`
	Interface string `json:"interface,omitempty"`
	Store     string `json:"store,omitempty"`
}

type typedFact struct {
	System string   `json:"system"`
	Kinds  []string `json:"kinds"`
}

type typedLock struct {
	Table   string   `json:"table"`
	Store   string   `json:"store"`
	Method  string   `json:"method"`
	Callers []string `json:"callers"`
}

type typedOutput struct {
	Edges    []typedEdge `json:"edges"`
	Facts    []typedFact `json:"facts"`
	RowLocks []typedLock `json:"row_locks"`
	Gaps     []string    `json:"gaps"`
}

type typedWorld struct {
	root     string
	fset     *token.FileSet
	packages map[string]*listedPackage
	importer types.Importer
	appNames []string
	types    []*types.Named
	typePkg  map[*types.Named]string
	iface    map[string][]string
}

func collectTyped(root string) typedOutput {
	world := &typedWorld{root: root, fset: token.NewFileSet(), packages: map[string]*listedPackage{}, typePkg: map[*types.Named]string{}, iface: map[string][]string{}}
	if err := world.load(); err != nil {
		return typedOutput{Gaps: []string{err.Error()}}
	}
	output := typedOutput{Edges: []typedEdge{}, Facts: []typedFact{}, RowLocks: []typedLock{}, Gaps: []string{}}
	edgeSet := map[string]bool{}
	for _, path := range sortedApplicationPaths(world.packages) {
		listed := world.packages[path]
		system := strings.TrimPrefix(path, modulePath+"internal/application/")
		info, files := world.check(listed)
		if info == nil {
			output.Gaps = append(output.Gaps, path+": type check failed")
			continue
		}
		for _, file := range files {
			ast.Inspect(file, func(node ast.Node) bool {
				call, ok := node.(*ast.CallExpr)
				if !ok {
					return true
				}
				world.eachEdge(system, path, call, info, func(edge typedEdge) {
					key := edge.From + "\x00" + edge.To + "\x00" + edge.Method + "\x00" + edge.Interface + "\x00" + edge.Store
					if edgeSet[key] {
						return
					}
					edgeSet[key] = true
					output.Edges = append(output.Edges, edge)
				})
				return true
			})
		}
		kinds := world.emittedFacts(system, files, info, &output.Gaps)
		output.Facts = append(output.Facts, typedFact{System: system, Kinds: kinds})
	}
	output.RowLocks = world.rowLocks()
	sort.Slice(output.Edges, func(i, j int) bool {
		a, b := output.Edges[i], output.Edges[j]
		if a.From != b.From {
			return a.From < b.From
		}
		if a.To != b.To {
			return a.To < b.To
		}
		return a.Method < b.Method
	})
	sort.Slice(output.Facts, func(i, j int) bool { return output.Facts[i].System < output.Facts[j].System })
	sort.Slice(output.RowLocks, func(i, j int) bool {
		if output.RowLocks[i].Store != output.RowLocks[j].Store {
			return output.RowLocks[i].Store < output.RowLocks[j].Store
		}
		return output.RowLocks[i].Table < output.RowLocks[j].Table
	})
	return output
}

func sortedApplicationPaths(packages map[string]*listedPackage) []string {
	paths := []string{}
	for path := range packages {
		if strings.HasPrefix(path, modulePath+"internal/application/") && !strings.Contains(path, "/internal/application/") == false {
			trimmed := strings.TrimPrefix(path, modulePath+"internal/application/")
			if trimmed != "" && !strings.Contains(trimmed, "/") {
				paths = append(paths, path)
			}
		}
	}
	sort.Strings(paths)
	return paths
}

func (w *typedWorld) load() error {
	command := exec.Command("go", "list", "-deps", "-export", "-json", "-tags", "postgres,river", "./cmd/...", "./internal/application/...")
	command.Dir = w.root
	raw, err := command.Output()
	if err != nil {
		return fmt.Errorf("go list: %v", err)
	}
	decoder := json.NewDecoder(bytes.NewReader(raw))
	for {
		var listed listedPackage
		if err := decoder.Decode(&listed); err == io.EOF {
			break
		} else if err != nil {
			return err
		}
		w.packages[listed.ImportPath] = &listed
	}
	exports := map[string]string{}
	for path, listed := range w.packages {
		if listed.Export != "" {
			exports[path] = listed.Export
		}
	}
	lookup := func(path string) (io.ReadCloser, error) {
		export, ok := exports[path]
		if !ok {
			return nil, fmt.Errorf("no export data for %s", path)
		}
		return os.Open(export)
	}
	w.importer = importer.ForCompiler(w.fset, "gc", lookup)
	for _, path := range sortedApplicationPaths(w.packages) {
		w.appNames = append(w.appNames, strings.TrimPrefix(path, modulePath+"internal/application/"))
	}
	return nil
}

func (w *typedWorld) check(listed *listedPackage) (*types.Info, []*ast.File) {
	names := listed.CompiledGoFiles
	if len(names) == 0 {
		names = listed.GoFiles
	}
	files := []*ast.File{}
	for _, name := range names {
		if !filepath.IsAbs(name) {
			name = filepath.Join(listed.Dir, name)
		}
		parsed, err := parser.ParseFile(w.fset, name, nil, 0)
		if err != nil {
			continue
		}
		files = append(files, parsed)
	}
	info := &types.Info{
		Types:      map[ast.Expr]types.TypeAndValue{},
		Defs:       map[*ast.Ident]types.Object{},
		Uses:       map[*ast.Ident]types.Object{},
		Selections: map[*ast.SelectorExpr]*types.Selection{},
	}
	config := types.Config{Importer: w.importer, Error: func(error) {}}
	checked, _ := config.Check(listed.ImportPath, w.fset, files, info)
	if checked == nil {
		return nil, nil
	}
	return info, files
}

func derefNamed(t types.Type) *types.Named {
	for {
		switch typed := t.(type) {
		case *types.Pointer:
			t = typed.Elem()
		case *types.Named:
			return typed
		case *types.Alias:
			t = types.Unalias(typed)
		default:
			return nil
		}
	}
}

func (w *typedWorld) owner(path string) (string, string, string) {
	if strings.HasPrefix(path, modulePath+"internal/application/") {
		system := strings.TrimPrefix(path, modulePath+"internal/application/")
		if !strings.Contains(system, "/") {
			return system, "", ""
		}
	}
	if strings.HasPrefix(path, modulePath+"internal/adapters/postgres/") {
		store := strings.TrimPrefix(path, modulePath)
		return "store:" + store, "", store
	}
	return "", "", ""
}

var storeStem = regexp.MustCompile(`(.*)store$`)

func (w *typedWorld) storeOwner(store string) string {
	base := filepath.Base(store)
	stem := strings.TrimSuffix(base, "store")
	for _, system := range w.appNames {
		if system == stem {
			return system
		}
	}
	candidates := []string{}
	for _, system := range w.appNames {
		if strings.HasPrefix(system, stem) {
			candidates = append(candidates, system)
		}
	}
	if len(candidates) == 1 {
		return candidates[0]
	}
	return "store:" + store
}

func (w *typedWorld) eachEdge(system, sourcePath string, call *ast.CallExpr, info *types.Info, emit func(typedEdge)) {
	selector, ok := call.Fun.(*ast.SelectorExpr)
	if !ok {
		return
	}
	function, _ := info.Uses[selector.Sel].(*types.Func)
	if function == nil {
		return
	}
	selection := info.Selections[selector]
	if selection == nil {
		packagePath := function.Pkg().Path()
		if target, _, store := w.owner(packagePath); target != "" && target != system {
			emit(typedEdge{From: system, To: target, Method: function.Name(), Store: store})
		}
		return
	}
	receiver := selection.Recv()
	ifaceName := ""
	var iface *types.Interface
	if named := derefNamed(receiver); named != nil {
		if interfaceType, isInterface := named.Underlying().(*types.Interface); isInterface {
			iface = interfaceType
			if named.Obj().Pkg() != nil {
				ifaceName = named.Obj().Pkg().Path() + "." + named.Obj().Name()
			}
		} else {
			if named.Obj().Pkg() == nil {
				return
			}
			target, _, store := w.owner(named.Obj().Pkg().Path())
			if target == "" {
				return
			}
			if store != "" {
				target = w.storeOwner(store)
			} else if target == system {
				return
			}
			emit(typedEdge{From: system, To: target, Method: function.Name(), Store: store})
			return
		}
	} else if direct, ok := receiver.Underlying().(*types.Interface); ok {
		iface = direct
	}
	if iface == nil {
		return
	}
	implementers := w.implementers(iface, ifaceName)
	if len(implementers) == 0 {
		return
	}
	if len(implementers) > implementerThreshold {
		emit(typedEdge{From: system, To: "interface:" + ifaceName, Method: function.Name(), ViaPort: true, Interface: ifaceName})
		return
	}
	for _, implementer := range implementers {
		target, _, store := w.owner(implementer)
		if store != "" {
			target = w.storeOwner(store)
		}
		if target == "" {
			continue
		}
		if store == "" && target == system {
			continue
		}
		emit(typedEdge{From: system, To: target, Method: function.Name(), ViaPort: true, Interface: ifaceName, Store: store})
	}
}

func (w *typedWorld) implementers(iface *types.Interface, name string) []string {
	if cached, ok := w.iface[name]; ok {
		return cached
	}
	w.iface[name] = []string{}
	if w.types == nil {
		w.collectModuleTypes()
	}
	found := map[string]bool{}
	for _, named := range w.types {
		if types.IsInterface(named) {
			continue
		}
		if types.Implements(named, iface) || types.Implements(types.NewPointer(named), iface) {
			path := w.typePkg[named]
			if strings.HasPrefix(path, modulePath+"internal/application/") || strings.HasPrefix(path, modulePath+"internal/adapters/postgres/") {
				found[path] = true
			}
		}
	}
	paths := []string{}
	for path := range found {
		paths = append(paths, path)
	}
	sort.Strings(paths)
	w.iface[name] = paths
	return paths
}

func (w *typedWorld) collectModuleTypes() {
	paths := []string{}
	for path := range w.packages {
		if strings.HasPrefix(path, modulePath+"internal/") && !strings.HasPrefix(path, modulePath+"internal/application/") || strings.HasPrefix(path, modulePath+"internal/application/") {
			paths = append(paths, path)
		}
	}
	sort.Strings(paths)
	for _, path := range paths {
		pkg, err := w.importer.Import(path)
		if err != nil || pkg == nil {
			continue
		}
		for _, name := range pkg.Scope().Names() {
			object, ok := pkg.Scope().Lookup(name).(*types.TypeName)
			if !ok {
				continue
			}
			named, ok := object.Type().(*types.Named)
			if !ok || named.Obj().Pkg() == nil {
				continue
			}
			w.types = append(w.types, named)
			w.typePkg[named] = named.Obj().Pkg().Path()
		}
	}
}

func (w *typedWorld) emittedFacts(system string, files []*ast.File, info *types.Info, gaps *[]string) []string {
	found := map[string]bool{}
	for _, file := range files {
		assignments := fileAssignments(file)
		ast.Inspect(file, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || selector.Sel.Name != "RecordTx" {
				return true
			}
			for _, argument := range call.Args {
				literal := factLiteral(argument, assignments)
				if literal == nil {
					continue
				}
				for _, element := range literal.Elts {
					pair, ok := element.(*ast.KeyValueExpr)
					if !ok {
						continue
					}
					key, ok := pair.Key.(*ast.Ident)
					if !ok || key.Name != "Kind" {
						continue
					}
					values := constStrings(pair.Value, assignments, info, 0)
					if len(values) == 0 {
						position := w.fset.Position(pair.Value.Pos())
						*gaps = append(*gaps, fmt.Sprintf("%s:%d: fact kind is not a constant", position.Filename, position.Line))
					}
					for _, value := range values {
						found[value] = true
					}
				}
			}
			return true
		})
	}
	kinds := []string{}
	for kind := range found {
		kinds = append(kinds, kind)
	}
	sort.Strings(kinds)
	return kinds
}

func fileAssignments(file *ast.File) map[string][]ast.Expr {
	values := map[string][]ast.Expr{}
	ast.Inspect(file, func(node ast.Node) bool {
		switch typed := node.(type) {
		case *ast.AssignStmt:
			if len(typed.Lhs) == len(typed.Rhs) {
				for index, lhs := range typed.Lhs {
					if ident, ok := lhs.(*ast.Ident); ok {
						values[ident.Name] = append(values[ident.Name], typed.Rhs[index])
					}
				}
			}
		case *ast.ValueSpec:
			if len(typed.Names) == len(typed.Values) {
				for index, name := range typed.Names {
					values[name.Name] = append(values[name.Name], typed.Values[index])
				}
			}
		}
		return true
	})
	return values
}

func factLiteral(expr ast.Expr, assignments map[string][]ast.Expr) *ast.CompositeLit {
	for depth := 0; depth < 6; depth++ {
		switch typed := expr.(type) {
		case *ast.CompositeLit:
			if typeName(typed.Type) == "Fact" {
				return typed
			}
			return nil
		case *ast.Ident:
			next, ok := assignments[typed.Name]
			if !ok || len(next) == 0 {
				return nil
			}
			expr = next[0]
		default:
			return nil
		}
	}
	return nil
}

func constStrings(expr ast.Expr, assignments map[string][]ast.Expr, info *types.Info, depth int) []string {
	if depth > 8 || expr == nil {
		return nil
	}
	if value := info.Types[expr].Value; value != nil && value.Kind() == constant.String {
		return []string{constant.StringVal(value)}
	}
	if ident, ok := expr.(*ast.Ident); ok {
		found := []string{}
		seen := map[string]bool{}
		for _, next := range assignments[ident.Name] {
			for _, value := range constStrings(next, assignments, info, depth+1) {
				if !seen[value] {
					seen[value] = true
					found = append(found, value)
				}
			}
		}
		return found
	}
	return nil
}

var (
	lockStatement = regexp.MustCompile(`(?is)for\s+(update|share)`)
	lockTable     = regexp.MustCompile(`(?i)(?:from|update|into)\s+([a-zA-Z0-9_".]+)`)
)

func (w *typedWorld) rowLocks() []typedLock {
	base := filepath.Join(w.root, "internal", "adapters", "postgres")
	locks := map[string]typedLock{}
	filepath.WalkDir(base, func(path string, entry os.DirEntry, err error) error {
		if err != nil || entry.IsDir() || !strings.HasSuffix(entry.Name(), ".go") || strings.HasSuffix(entry.Name(), "_test.go") {
			return nil
		}
		raw, readErr := os.ReadFile(path)
		if readErr != nil {
			return nil
		}
		text := string(raw)
		store := strings.TrimPrefix(filepath.ToSlash(filepath.Dir(path)), strings.TrimSuffix(filepath.ToSlash(w.root), "/")+"/")
		for _, location := range lockStatement.FindAllStringIndex(text, -1) {
			start := location[0] - 800
			if start < 0 {
				start = 0
			}
			window := text[start:location[0]]
			tables := lockTable.FindAllStringSubmatch(window, -1)
			if len(tables) == 0 {
				continue
			}
			table := normalizeTableName(tables[len(tables)-1][1])
			if table == "" {
				continue
			}
			method := storeFunction(text, location[0])
			key := store + "\x00" + method + "\x00" + table
			locks[key] = typedLock{Table: table, Store: store, Method: method}
		}
		return nil
	})
	callerCache := map[string][]string{}
	result := []typedLock{}
	for _, lock := range locks {
		cacheKey := lock.Store + "\x00" + lock.Method
		if _, ok := callerCache[cacheKey]; !ok {
			callerCache[cacheKey] = w.lockCallers(lock.Store, lock.Method)
		}
		lock.Callers = callerCache[cacheKey]
		result = append(result, lock)
	}
	return result
}

var storeFunctionRE = regexp.MustCompile(`(?m)^func\s+(?:\([^)]*\)\s*)?([A-Za-z0-9_]+)\s*\(`)

func storeFunction(text string, position int) string {
	matches := storeFunctionRE.FindAllStringSubmatch(text[:position], -1)
	if len(matches) == 0 {
		return ""
	}
	return matches[len(matches)-1][1]
}

func (w *typedWorld) lockCallers(store, method string) []string {
	directory := filepath.Join(w.root, store)
	functions := map[string][]string{}
	for _, name := range []string{} {
		_ = name
	}
	entries, err := os.ReadDir(directory)
	if err != nil {
		return nil
	}
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".go") || strings.HasSuffix(entry.Name(), "_test.go") {
			continue
		}
		parsed, parseErr := parser.ParseFile(token.NewFileSet(), filepath.Join(directory, entry.Name()), nil, 0)
		if parseErr != nil {
			continue
		}
		for _, declaration := range parsed.Decls {
			decl, ok := declaration.(*ast.FuncDecl)
			if !ok || decl.Body == nil {
				continue
			}
			calls := []string{}
			ast.Inspect(decl.Body, func(node ast.Node) bool {
				call, isCall := node.(*ast.CallExpr)
				if !isCall {
					return true
				}
				switch fun := call.Fun.(type) {
				case *ast.Ident:
					calls = append(calls, fun.Name)
				case *ast.SelectorExpr:
					calls = append(calls, fun.Sel.Name)
				}
				return true
			})
			functions[decl.Name.Name] = calls
		}
	}
	reached := map[string]bool{}
	frontier := []string{method}
	for depth := 0; depth < 4 && len(frontier) > 0; depth++ {
		next := []string{}
		for _, name := range frontier {
			for caller, calls := range functions {
				protected := reached[caller]
				if protected {
					continue
				}
				for _, called := range calls {
					if called == name {
						reached[caller] = true
						next = append(next, caller)
						break
					}
				}
			}
		}
		frontier = next
	}
	exported := []string{}
	for name := range reached {
		if name != method && ast.IsExported(name) {
			exported = append(exported, name)
		}
	}
	sort.Strings(exported)
	return exported
}

func normalizeTableName(raw string) string {
	name := strings.Trim(raw, `."`)
	if index := strings.LastIndex(name, "."); index >= 0 {
		name = name[index+1:]
	}
	return strings.Trim(name, `"`)
}
