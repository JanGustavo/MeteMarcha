package platform

import (
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	// Único lugar do projeto que conhece o driver SQLite (usa cgo).
	// Trocar de driver significa mexer só neste arquivo.
	"github.com/mattn/go-sqlite3"
)

// OpenDB abre (e cria, se preciso) o banco SQLite.
//
// Opções importantes do DSN:
//   - _foreign_keys=on:   o SQLite só respeita chaves estrangeiras se pedirmos.
//   - _journal_mode=WAL:  leituras não bloqueiam a escrita.
//   - _busy_timeout=5000: em vez de falhar com "database is locked", espera até 5 s.
//   - _txlock=immediate:  toda transação já começa reservando a escrita. Com isso
//     duas transações "ler a contagem e depois inserir" nunca se intercalam; é isto
//     que protege o limite de participantes sob entradas simultâneas.
func OpenDB(path string) (*sql.DB, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
		return nil, fmt.Errorf("criar pasta do banco: %w", err)
	}
	dsn := "file:" + path + "?_foreign_keys=on&_journal_mode=WAL&_busy_timeout=5000&_txlock=immediate&_synchronous=NORMAL"
	db, err := sql.Open("sqlite3", dsn)
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		db.Close()
		return nil, fmt.Errorf("abrir banco: %w", err)
	}
	return db, nil
}

// IsUniqueViolation informa se o erro veio de uma restrição UNIQUE ou de chave
// primária duplicada. Os módulos usam isso para transformar "já existe" em
// respostas claras (e-mail repetido, publicação repetida, etc.).
func IsUniqueViolation(err error) bool {
	var se sqlite3.Error
	if errors.As(err, &se) {
		return se.ExtendedCode == sqlite3.ErrConstraintUnique || se.ExtendedCode == sqlite3.ErrConstraintPrimaryKey
	}
	return false
}
