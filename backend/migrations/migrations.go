// Package migrations embute os arquivos .sql no binário.
// Assim o programa carrega o esquema sozinho, sem depender de uma pasta
// existir na VPS. Os arquivos rodam em ordem alfabética (0001, 0002, ...).
package migrations

import "embed"

//go:embed *.sql
var FS embed.FS
