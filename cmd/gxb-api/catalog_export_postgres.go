//go:build postgres

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"time"

	opcatalogsource "gxb.local/backend/v2/internal/adapters/operatorcatalog"
)

// runCatalogCommand implements `gxb-api catalog export --out <file>`
// (I11A_OPERATOR_COMMANDS_V1 ruling 9). It reads the content this binary was
// built with, so the file always matches the backend that serves grants.
func runCatalogCommand(args []string) int {
	if len(args) == 0 || args[0] != "export" {
		fmt.Fprintln(os.Stderr, "usage: gxb-api catalog export --out <file>")
		return 2
	}
	flags := flag.NewFlagSet("catalog export", flag.ContinueOnError)
	out := flags.String("out", "", "path of the operator catalogue file")
	if err := flags.Parse(args[1:]); err != nil {
		return 2
	}
	if *out == "" || flags.NArg() != 0 {
		fmt.Fprintln(os.Stderr, "usage: gxb-api catalog export --out <file>")
		return 2
	}
	document, err := opcatalogsource.Load(time.Now().UTC())
	if err != nil {
		fmt.Fprintf(os.Stderr, "catalog export: %v\n", err)
		return 1
	}
	encoded, err := json.MarshalIndent(document, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "catalog export: %v\n", err)
		return 1
	}
	encoded = append(encoded, '\n')
	if err := os.WriteFile(*out, encoded, 0o644); err != nil {
		fmt.Fprintf(os.Stderr, "catalog export: %v\n", err)
		return 1
	}
	fmt.Printf("catalog export: %d entries, content revision %s\n", len(document.Entries), document.ContentRevision)
	return 0
}
