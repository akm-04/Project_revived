//go:build !postgres

package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Fprintln(os.Stderr, "gxb-client-log requires the postgres build")
	os.Exit(1)
}
