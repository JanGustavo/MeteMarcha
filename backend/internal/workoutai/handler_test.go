package workoutai

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func fixture() Workout {
	return Workout{Name: "Mini treino", Type: "CUSTOM", Days: []Day{{Letter: "A", Name: "Início", Exercises: []Exercise{{Name: "Flexão na parede", Muscle: "Peito", Equipment: "Peso Corporal", Rest: 60, Volume: "2x8"}, {Name: "Agachamento livre", Muscle: "Quadríceps", Equipment: "Peso Corporal", Rest: 60, Volume: "2x8"}, {Name: "Ponte de glúteos", Muscle: "Glúteo", Equipment: "Peso Corporal", Rest: 60, Volume: "2x8"}}}}}
}
func TestValidateDraft(t *testing.T) {
	in := Input{Mode: "generate", Focus: "calistenia", Minutes: 15}
	w := fixture()
	if !validWorkout(w, in) {
		t.Fatal("valid rejected")
	}
	w.Days[0].Exercises[0].Equipment = "Máquina"
	if validWorkout(w, in) {
		t.Fatal("unavailable equipment accepted")
	}
	w = fixture()
	w.Days[0].Exercises[0].Volume = "9x99"
	if validWorkout(w, in) {
		t.Fatal("excess volume accepted")
	}
}
func TestAIEndpoint(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer test-key" {
			t.Error("missing key")
		}
		var input map[string]any
		json.NewDecoder(r.Body).Decode(&input)
		if !strings.Contains(input["messages"].([]any)[0].(map[string]any)["content"].(string), "catálogo") {
			t.Error("missing constraints")
		}
		draft, _ := json.Marshal(fixture())
		json.NewEncoder(w).Encode(map[string]any{"choices": []any{map[string]any{"message": map[string]string{"content": string(draft)}}}})
	}))
	defer upstream.Close()
	h := NewHandler()
	h.key = "test-key"
	h.endpoint = upstream.URL
	h.client = upstream.Client()
	req := httptest.NewRequest("POST", "/v1/ai/workouts", strings.NewReader(`{"mode":"generate","focus":"calistenia","minutes":15}`)).WithContext(context.Background())
	response := httptest.NewRecorder()
	h.generate(response, req)
	if response.Code != 200 {
		t.Fatalf("response: %d %s", response.Code, response.Body.String())
	}
	if strings.Contains(response.Body.String(), "test-key") {
		t.Fatal("key leaked")
	}
	next := httptest.NewRecorder()
	h.generate(next, httptest.NewRequest("POST", "/v1/ai/workouts", strings.NewReader(`{"mode":"generate","focus":"calistenia","minutes":15}`)))
	if next.Code != 429 {
		t.Fatal("rate limit missing")
	}
}
func TestAIUnavailable(t *testing.T) {
	h := NewHandler()
	h.key = ""
	response := httptest.NewRecorder()
	h.generate(response, httptest.NewRequest("POST", "/v1/ai/workouts", strings.NewReader(`{"mode":"generate","focus":"calistenia","minutes":15}`)))
	if response.Code != 503 {
		t.Fatal(response.Code)
	}
}

func TestCatalogReferencesAreAuthoritative(t *testing.T) {
	w := fixture()
	w.Days[0].Exercises[0].Link = "https://malicious.example/video"
	w.Days[0].Exercises[1].CatalogID = "wall-push-up"
	w.Days[0].Exercises[1].Link = "https://malicious.example/video"
	enrichReferences(&w)
	if w.Days[0].Exercises[0].CatalogID != "wall-push-up" || w.Days[0].Exercises[0].Link != "https://www.youtube.com/watch?v=t6wxV5jG0Vg" {
		t.Fatal("wall reference missing")
	}
	if w.Days[0].Exercises[1].CatalogID != "bodyweight-squat" || w.Days[0].Exercises[1].Link != "" {
		t.Fatal("invented reference accepted")
	}
}
