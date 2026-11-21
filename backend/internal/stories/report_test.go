package stories

import "testing"

func TestValidateWorkoutReport(t *testing.T) {
	valid := `{"version":1,"title":"Treino A","date":"2026-11-20","duration_seconds":60,"sets":[{"exercise":"Supino","number":1,"weight_kg":20,"reps":10,"side":"ambos","completed":true,"equipment":"barra","notes":"","at":"2026-11-20"}]}`
	if _, err := validateReport(valid); err != nil {
		t.Fatal(err)
	}
	for _, raw := range []string{`{}`, `{"version":99}`, `{"private_history":true}`} {
		if _, err := validateReport(raw); err == nil {
			t.Fatalf("accepted %s", raw)
		}
	}
}
