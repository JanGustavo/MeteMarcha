package platform

import (
	"database/sql"
	"fmt"
	"io/fs"
	"sort"
	"time"
)

// Migrate aplica, em ordem, os arquivos .sql que ainda não rodaram.
// A tabela schema_migrations lembra quais já foram aplicados. Cada arquivo roda
// dentro de uma transação: ou aplica por inteiro, ou nada muda.
// Para evoluir o esquema, crie um arquivo novo (0005_...) — nunca edite um antigo.
func Migrate(db *sql.DB, files fs.FS) error {
	if _, err := db.Exec(`CREATE TABLE IF NOT EXISTS schema_migrations (
		version    TEXT PRIMARY KEY,
		applied_at INTEGER NOT NULL
	)`); err != nil {
		return err
	}

	names, err := fs.Glob(files, "*.sql")
	if err != nil {
		return err
	}
	sort.Strings(names)

	for _, name := range names {
		var already int
		if err := db.QueryRow(`SELECT COUNT(*) FROM schema_migrations WHERE version = ?`, name).Scan(&already); err != nil {
			return err
		}
		if already > 0 {
			continue
		}
		body, err := fs.ReadFile(files, name)
		if err != nil {
			return err
		}
		tx, err := db.Begin()
		if err != nil {
			return err
		}
		if _, err := tx.Exec(string(body)); err != nil {
			tx.Rollback()
			return fmt.Errorf("migração %s: %w", name, err)
		}
		if _, err := tx.Exec(`INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)`, name, time.Now().Unix()); err != nil {
			tx.Rollback()
			return err
		}
		if err := tx.Commit(); err != nil {
			return err
		}
	}
	return nil
}
