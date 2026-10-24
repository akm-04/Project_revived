//go:build !postgres

package main

import "fmt"

func main() {
	fmt.Println("gxb-api: PostgreSQL runtime disabled; build the I4 candidate with -tags postgres")
}
