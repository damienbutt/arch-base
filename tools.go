//go:build tools

package main

// This file declares dependencies that are used for development tools.
// The build tag "tools" ensures this file is not included in regular builds.
// Run `go mod tidy` to ensure these tools are downloaded and available.

import (
	_ "github.com/evilmartians/lefthook"
	_ "github.com/google/go-licenses"
	_ "github.com/goreleaser/goreleaser"
	_ "golang.org/x/tools/cmd/goimports"
	_ "golang.org/x/vuln/cmd/govulncheck"
)
