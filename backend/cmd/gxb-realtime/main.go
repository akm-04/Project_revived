//go:build !postgres

package main

import "fmt"

func main() {
	fmt.Println("gxb-realtime: PostgreSQL runtime disabled; build the I4 candidate with -tags postgres")
}
