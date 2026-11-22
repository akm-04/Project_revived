//go:build !postgres

package main

import "fmt"

func main() { fmt.Println("ranking backfill unavailable; requires -tags postgres") }
