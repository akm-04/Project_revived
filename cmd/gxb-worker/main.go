//go:build !postgres || !river

package main

import "fmt"

func main() {
	fmt.Println("gxb-worker: Guild broadcast runtime unavailable; production requires -tags postgres,river")
}
