package platform

import (
	"context"
	"path/filepath"
	"testing"
	"time"
)

// O limite de participantes depende de uma propriedade do banco: uma transação
// já começa reservando a escrita (BEGIN IMMEDIATE). Este teste verifica isso de
// forma determinística: com uma transação aberta, outra NÃO pode nem começar.
func TestTransactionsReserveWriteLockImmediately(t *testing.T) {
	db, err := OpenDB(filepath.Join(t.TempDir(), "t.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	first, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	started := make(chan struct{})
	go func() {
		second, err := db.BeginTx(context.Background(), nil)
		if err == nil {
			second.Rollback()
		}
		close(started)
	}()

	select {
	case <-started:
		t.Fatal("a segunda transação começou enquanto a primeira segurava a escrita: " +
			"duas entradas simultâneas poderiam passar juntas pela contagem de participantes")
	case <-time.After(300 * time.Millisecond):
	}
	first.Rollback()
	select {
	case <-started:
	case <-time.After(5 * time.Second):
		t.Fatal("a segunda transação deveria prosseguir depois que a primeira terminou")
	}
}

func TestForeignKeysAreEnforced(t *testing.T) {
	db, err := OpenDB(filepath.Join(t.TempDir(), "t.db"))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	db.Exec(`CREATE TABLE pai (id INTEGER PRIMARY KEY)`)
	db.Exec(`CREATE TABLE filho (pai_id INTEGER REFERENCES pai(id))`)
	if _, err := db.Exec(`INSERT INTO filho (pai_id) VALUES (999)`); err == nil {
		t.Fatal("chaves estrangeiras deveriam estar ligadas")
	}
}
