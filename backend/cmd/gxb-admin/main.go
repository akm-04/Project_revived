//go:build !postgres

package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Fprintln(os.Stderr, "gxb-admin: requires -tags postgres; refusing to run an unaudited operator command without a database")
	os.Exit(2)
}
