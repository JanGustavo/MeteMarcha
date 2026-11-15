package app

import (
	"io/fs"
	"path/filepath"
	"testing"
	"testing/fstest"

	"github.com/JanGustavo/MeteMarcha/backend/internal/platform"
	"github.com/JanGustavo/MeteMarcha/backend/migrations"
)

func TestMultiGroupMigrationPreservesExistingSelection(t *testing.T) {
	db, err := platform.OpenDB(filepath.Join(t.TempDir(), "old.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	old := fstest.MapFS{}
	for _, name := range []string{"0001_auth.sql", "0002_groups.sql", "0003_media.sql", "0004_stories.sql"} {
		body, err := fs.ReadFile(migrations.FS, name)
		if err != nil {
			t.Fatal(err)
		}
		old[name] = &fstest.MapFile{Data: body}
	}
	if err := platform.Migrate(db, old); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO users (id, email, display_name, password_hash, created_at) VALUES ('u', 'u@example.com', 'U', 'hash', 1)`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO groups (id, name, created_by, created_at) VALUES ('g', 'Antigo', 'u', 1)`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO group_members (user_id, group_id, role, joined_at) VALUES ('u', 'g', 'owner', 1)`); err != nil {
		t.Fatal(err)
	}
	if err := platform.Migrate(db, migrations.FS); err != nil {
		t.Fatal(err)
	}
	var active string
	if err := db.QueryRow(`SELECT group_id FROM active_groups WHERE user_id = 'u'`).Scan(&active); err != nil || active != "g" {
		t.Fatalf("grupo ativo migrado: %q %v", active, err)
	}
	if _, err := db.Exec(`INSERT INTO groups (id, name, created_by, created_at) VALUES ('h', 'Novo', 'u', 2)`); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec(`INSERT INTO group_members (user_id, group_id, role, joined_at) VALUES ('u', 'h', 'owner', 2)`); err != nil {
		t.Fatalf("migração ainda impede múltiplos grupos: %v", err)
	}
}
