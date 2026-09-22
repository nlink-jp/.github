// Command runtime-lists compares the credential lists a runtime declares in
// its internal/sandbox/lane.go (gem-agent, lagent) with the copy pathguard
// holds in testdata/runtime-lists.json, and exits 1 when they differ.
//
//	go run runtime-lists.go -lane <lane.go> -fixture <runtime-lists.json>
//
// (Flags, because go run takes every argument ending in .go as a source file.)
//
// pathguard cannot import the runtimes' internal packages, and the runtimes do
// not depend on pathguard yet, so check-org.sh is the one place that sees all
// three and holds them together (organization ADR-022). The lists are read
// with go/ast rather than a pattern: a reformatted declaration must not pass
// as a changed one, or the other way round.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
	"slices"
	"strconv"
)

type lists struct {
	CredentialDirs  []string `json:"credentialDirs"`
	HomeOnlyDirs    []string `json:"homeOnlyDirs"`
	CredentialFiles []string `json:"credentialFiles"`
	CredentialNames string   `json:"credentialNames"`
}

func main() {
	lane := flag.String("lane", "", "a runtime's internal/sandbox/lane.go")
	fixture := flag.String("fixture", "", "pathguard's testdata/runtime-lists.json")
	flag.Parse()
	if *lane == "" || *fixture == "" {
		fmt.Fprintln(os.Stderr, "usage: runtime-lists -lane <lane.go> -fixture <runtime-lists.json>")
		os.Exit(2)
	}
	got, err := fromLane(*lane)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	raw, err := os.ReadFile(*fixture)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	var want lists
	if err := json.Unmarshal(raw, &want); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	diffs := compare(got, want)
	for _, d := range diffs {
		fmt.Println(d)
	}
	if len(diffs) > 0 {
		os.Exit(1)
	}
}

func compare(got, want lists) []string {
	var out []string
	set := func(name string, g, w []string) {
		g, w = slices.Clone(g), slices.Clone(w)
		slices.Sort(g)
		slices.Sort(w)
		if !slices.Equal(g, w) {
			out = append(out, fmt.Sprintf("%s: lane.go %q, pathguard %q", name, g, w))
		}
	}
	set("credentialDirs", got.CredentialDirs, want.CredentialDirs)
	set("homeOnlyDirs", got.HomeOnlyDirs, want.HomeOnlyDirs)
	set("credentialFiles", got.CredentialFiles, want.CredentialFiles)
	if got.CredentialNames != want.CredentialNames {
		out = append(out, fmt.Sprintf("credentialNames: lane.go %q, pathguard %q", got.CredentialNames, want.CredentialNames))
	}
	return out
}

// fromLane reads the four package-level declarations. A missing one is an
// error, not an empty list: a renamed variable must not read as a list that
// shrank to nothing.
func fromLane(path string) (lists, error) {
	f, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
	if err != nil {
		return lists{}, err
	}
	var l lists
	found := map[string]bool{}
	for _, decl := range f.Decls {
		gd, ok := decl.(*ast.GenDecl)
		if !ok || gd.Tok != token.VAR {
			continue
		}
		for _, spec := range gd.Specs {
			vs := spec.(*ast.ValueSpec)
			for i, name := range vs.Names {
				if i >= len(vs.Values) {
					continue
				}
				v := vs.Values[i]
				switch name.Name {
				case "credentialDirs":
					l.CredentialDirs, err = strings(v)
				case "credentialFiles":
					l.CredentialFiles, err = strings(v)
				case "homeOnlyDirs":
					l.HomeOnlyDirs, err = mapKeys(v)
				case "credentialNames":
					l.CredentialNames, err = literal(v)
				default:
					continue
				}
				if err != nil {
					return lists{}, fmt.Errorf("%s: %s: %w", path, name.Name, err)
				}
				found[name.Name] = true
			}
		}
	}
	for _, n := range []string{"credentialDirs", "homeOnlyDirs", "credentialFiles", "credentialNames"} {
		if !found[n] {
			return lists{}, fmt.Errorf("%s: no declaration of %s", path, n)
		}
	}
	return l, nil
}

func strings(e ast.Expr) ([]string, error) {
	cl, ok := e.(*ast.CompositeLit)
	if !ok {
		return nil, fmt.Errorf("not a composite literal")
	}
	var out []string
	for _, el := range cl.Elts {
		s, err := literal(el)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, nil
}

func mapKeys(e ast.Expr) ([]string, error) {
	cl, ok := e.(*ast.CompositeLit)
	if !ok {
		return nil, fmt.Errorf("not a composite literal")
	}
	var out []string
	for _, el := range cl.Elts {
		kv, ok := el.(*ast.KeyValueExpr)
		if !ok {
			return nil, fmt.Errorf("not a key-value element")
		}
		s, err := literal(kv.Key)
		if err != nil {
			return nil, err
		}
		out = append(out, s)
	}
	return out, nil
}

func literal(e ast.Expr) (string, error) {
	bl, ok := e.(*ast.BasicLit)
	if !ok || bl.Kind != token.STRING {
		return "", fmt.Errorf("not a string literal")
	}
	return strconv.Unquote(bl.Value)
}
