//go:build !postgres || !river

package main

import "fmt"

func main() { fmt.Println("Guild broadcast deployment unavailable; requires -tags postgres,river") }
