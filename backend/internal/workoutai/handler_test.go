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
	w.Days[0].Exercises = append(w.Days[0].Exercises, Exercise{Name: "Exercício desconhecido", CatalogID: "wall-push-up", Link: "https://malicious.example/video"})
	enrichReferences(&w)
	if w.Days[0].Exercises[3].CatalogID != "" || w.Days[0].Exercises[3].Link != "" {
		t.Fatal("unknown exercise kept provider reference")
	}
	if w.Days[0].Exercises[0].CatalogID != "wall-push-up" || w.Days[0].Exercises[0].Link != "https://www.youtube.com/watch?v=UezGV10_wUA" {
		t.Fatal("wall reference missing")
	}
	if w.Days[0].Exercises[1].CatalogID != "bodyweight-squat" || w.Days[0].Exercises[1].Link != "https://www.youtube.com/watch?v=qrZs_1K1CFI" {
		t.Fatal("invented reference accepted")
	}
}

func gymFixture(split string) Workout {
	w := Workout{Name: "Academia", Type: "CUSTOM"}
	for i := 0; i < splitDays(split); i++ {
		w.Days = append(w.Days, Day{Letter: string(rune('A' + i)), Name: "Sessão", Exercises: []Exercise{
			{Name: "Supino reto com halteres", Muscle: "Peito", Equipment: "Haltere", Rest: 90, Volume: "3x10"},
			{Name: "Remada com halter", Muscle: "Costas", Equipment: "Haltere", Rest: 90, Volume: "3x10"},
			{Name: "Leg press", Muscle: "Quadríceps", Equipment: "Máquina", Rest: 120, Volume: "3x10"},
		}})
	}
	return w
}
func TestGymInputAndSplitValidation(t *testing.T) {
	in := Input{Mode: "generate", Focus: "musculacao", Minutes: 60, Split: "ABC", Goal: "hipertrofia", Experience: "intermediario", Equipment: []string{"Haltere", "Máquina", "Barra", "Cabo"}, Text: "Academia cheia, priorizar costas"}
	if !validInput(in) || !validWorkout(gymFixture("ABC"), in) {
		t.Fatal("gym draft rejected")
	}
	for _, split := range []string{"FULL_BODY", "AB", "ABC", "ABCD", "ABCDE"} {
		sample := in
		sample.Split = split
		if !validWorkout(gymFixture(split), sample) {
			t.Fatal("split rejected", split)
		}
	}
	if validWorkout(gymFixture("AB"), in) {
		t.Fatal("incomplete split accepted")
	}
	w := gymFixture("ABC")
	w.Days[1].Letter = "A"
	if validWorkout(w, in) {
		t.Fatal("duplicate day letter")
	}
	w = gymFixture("ABC")
	w.Days[0].Exercises[1] = w.Days[0].Exercises[0]
	if validWorkout(w, in) {
		t.Fatal("duplicate exercise")
	}
	w = gymFixture("ABC")
	w.Days[0].Exercises[0].Volume = "5x30"
	if validWorkout(w, in) {
		t.Fatal("excess volume")
	}
	in.Equipment = []string{"Peso Corporal"}
	if validWorkout(gymFixture("ABC"), in) {
		t.Fatal("unavailable equipment accepted")
	}
	for _, minutes := range []int{30, 45, 60, 75, 90} {
		sample := in
		sample.Minutes = minutes
		if !validInput(sample) {
			t.Fatal("duration rejected", minutes)
		}
	}
	in.Minutes = 25
	if validInput(in) {
		t.Fatal("invalid duration accepted")
	}
	in.Minutes = 60
	in.Text = strings.Repeat("a", 2001)
	if validInput(in) {
		t.Fatal("oversized preferences accepted")
	}
	calis := Input{Mode: "generate", Focus: "calistenia", Minutes: 15, Split: "ABC"}
	if validInput(calis) {
		t.Fatal("multi-day mini accepted")
	}
}
func TestGymEndpoint(t *testing.T) {
	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var input struct {
			Messages []struct {
				Content string `json:"content"`
			} `json:"messages"`
		}
		json.NewDecoder(r.Body).Decode(&input)
		if !strings.Contains(input.Messages[0].Content, "EXATAMENTE 3 dias") || !strings.Contains(input.Messages[1].Content, "Academia cheia") || !strings.Contains(input.Messages[0].Content, "Leg press") {
			t.Error("missing gym context")
		}
		draft, _ := json.Marshal(gymFixture("ABC"))
		json.NewEncoder(w).Encode(map[string]any{"choices": []any{map[string]any{"message": map[string]string{"content": string(draft)}}}})
	}))
	defer upstream.Close()
	h := NewHandler()
	h.key = "test-key"
	h.endpoint = upstream.URL
	h.client = upstream.Client()
	out := httptest.NewRecorder()
	h.generate(out, httptest.NewRequest("POST", "/v1/ai/workouts", strings.NewReader(`{"mode":"generate","focus":"musculacao","minutes":60,"split":"ABC","equipment":["Haltere","Máquina"],"text":"Academia cheia"}`)))
	if out.Code != 200 {
		t.Fatal(out.Code, out.Body.String())
	}
	var result struct {
		Workout Workout `json:"workout"`
	}
	json.Unmarshal(out.Body.Bytes(), &result)
	if len(result.Workout.Days) != 3 || result.Workout.Days[0].Exercises[0].Link == "" {
		t.Fatal("split/reference missing")
	}
}
