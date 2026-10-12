//go:build !postgres || !linux

package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Fprintln(os.Stderr, "profile media maintenance requires qualified Linux PostgreSQL build")
	os.Exit(1)
}
