package auth

import (
	"strings"
	"testing"
)

func TestPasswordHashAndVerify(t *testing.T) {
	hash, err := hashPassword("minha-senha-123", 1024)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(hash, "$argon2id$v=19$m=1024,t=1,p=4$") {
		t.Errorf("formato inesperado: %s", hash)
	}
	if strings.Contains(hash, "minha-senha") {
		t.Error("o hash não pode conter a senha")
	}
	if ok, err := verifyPassword("minha-senha-123", hash); err != nil || !ok {
		t.Errorf("senha correta: ok=%v err=%v", ok, err)
	}
	if ok, _ := verifyPassword("minha-senha-124", hash); ok {
		t.Error("senha errada aceita")
	}
	// sal aleatório: o mesmo texto gera hashes diferentes
	other, _ := hashPassword("minha-senha-123", 1024)
	if other == hash {
		t.Error("sal deveria ser aleatório")
	}
	// hash antigo continua válido mesmo se o custo padrão mudar (parâmetros ficam no texto)
	old, _ := hashPassword("x-senha-longa", 2048)
	if ok, _ := verifyPassword("x-senha-longa", old); !ok {
		t.Error("parâmetros devem vir do próprio hash")
	}
	for _, bad := range []string{"", "texto-qualquer", "$argon2id$v=19$m=1,t=1$x$y", "$bcrypt$v=19$m=1,t=1,p=1$AAAA$AAAA"} {
		if _, err := verifyPassword("x", bad); err == nil {
			t.Errorf("hash malformado %q deveria dar erro", bad)
		}
	}
}
