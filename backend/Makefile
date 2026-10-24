.PHONY: check test vet fmt arch dependency-policy oracles
check:
	./tools/check.sh

test:
	GOTOOLCHAIN=local go test ./...

vet:
	GOTOOLCHAIN=local go vet ./...

fmt:
	gofmt -w $$(find . -name '*.go' -not -path './vendor/*')

arch:
	GOTOOLCHAIN=local go test ./internal/archguard

dependency-policy:
	python3 tools/check_dependency_policy.py

oracles:
	python3 tools/verify_oracles.py --root /mnt/data
