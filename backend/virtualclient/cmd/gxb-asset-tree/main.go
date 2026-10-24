// Command gxb-asset-tree builds the virtual client's update tree (I85_HARNESS_BOUNDARY_V1 R4): the verified lazy-asset tarball,
// every member the lazy catalog names checked against the catalog MD5, laid out as the stock versionUpdatePath holds downloads.
package main

import (
	"archive/tar"
	"crypto/md5"
	"encoding/csv"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	tarball := flag.String("tarball", "", "verified asset tarball (.tar.zst)")
	catalog := flag.String("catalog", "", "lazy catalog CSV (path,basename,md5,size,cdn_object)")
	out := flag.String("out", "", "update tree directory to create (must not exist)")
	flag.Parse()
	summary, err := build(*tarball, *catalog, *out)
	if err != nil {
		fmt.Fprintln(os.Stderr, "gxb-asset-tree:", err)
		os.Exit(1)
	}
	encoded, _ := json.MarshalIndent(summary, "", " ")
	fmt.Println(string(encoded))
}

type summary struct {
	Tarball        string `json:"tarball"`
	CatalogObjects int    `json:"catalog_objects"`
	Verified       int    `json:"verified"`
	Absent         int    `json:"catalog_absent"`
	Uncatalogued   int    `json:"uncatalogued_skipped"`
}

func readCatalog(path string) (map[string]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	rows, err := csv.NewReader(file).ReadAll()
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 || strings.Join(rows[0][:3], ",") != "path,basename,md5" {
		return nil, errors.New("catalog header is not path,basename,md5,...")
	}
	digests := make(map[string]string, len(rows)-1)
	for _, row := range rows[1:] {
		digests[row[0]] = row[2]
	}
	return digests, nil
}

func build(tarball, catalogPath, out string) (summary, error) {
	result := summary{Tarball: filepath.Base(tarball)}
	digests, err := readCatalog(catalogPath)
	if err != nil {
		return result, err
	}
	result.CatalogObjects = len(digests)
	if err := os.Mkdir(out, 0o755); err != nil {
		return result, err
	}
	decompress := exec.Command("zstd", "-dc", tarball)
	stream, err := decompress.StdoutPipe()
	if err != nil {
		return result, err
	}
	if err := decompress.Start(); err != nil {
		return result, err
	}
	reader := tar.NewReader(stream)
	for {
		header, err := reader.Next()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return result, err
		}
		if header.Typeflag != tar.TypeReg && header.Typeflag != tar.TypeLink {
			continue
		}
		name := filepath.Clean(header.Name)
		if !filepath.IsLocal(name) || !filepath.IsLocal(header.Linkname) && header.Typeflag == tar.TypeLink {
			return result, fmt.Errorf("member path escapes the tree: %s", header.Name)
		}
		want, catalogued := digests[name]
		if !catalogued {
			result.Uncatalogued++
			continue
		}
		got, err := extract(reader, header, out)
		if err != nil {
			return result, err
		}
		if got != want {
			return result, fmt.Errorf("%s: md5 %s, catalog %s", name, got, want)
		}
		result.Verified++
		delete(digests, name)
	}
	if err := decompress.Wait(); err != nil {
		return result, err
	}
	result.Absent = len(digests)
	return result, nil
}

// extract writes one member under out and returns its MD5; a hard link member is materialised from the file it links to.
func extract(reader *tar.Reader, header *tar.Header, out string) (string, error) {
	if header.Typeflag != tar.TypeLink {
		return writeMember(filepath.Join(out, filepath.Clean(header.Name)), reader)
	}
	linked, err := os.Open(filepath.Join(out, filepath.Clean(header.Linkname)))
	if err != nil {
		return "", fmt.Errorf("%s links to %s: %w", header.Name, header.Linkname, err)
	}
	defer linked.Close()
	return writeMember(filepath.Join(out, filepath.Clean(header.Name)), linked)
}

func writeMember(path string, content io.Reader) (string, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return "", err
	}
	file, err := os.Create(path)
	if err != nil {
		return "", err
	}
	defer file.Close()
	hash := md5.New()
	if _, err := io.Copy(io.MultiWriter(file, hash), content); err != nil {
		return "", err
	}
	return hex.EncodeToString(hash.Sum(nil)), nil
}
