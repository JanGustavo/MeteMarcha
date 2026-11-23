package exercisecatalog

import (
	"regexp"
	"testing"
)

func TestCatalogIntegrity(t *testing.T) {
	ids := map[string]bool{}
	aliases := map[string]string{}
	videoRE := regexp.MustCompile(`^https://www\.youtube\.com/watch\?v=[\w-]{11}$`)
	for _, entry := range Entries {
		if entry.ID == "" || ids[entry.ID] {
			t.Fatal("duplicate/empty id", entry.ID)
		}
		ids[entry.ID] = true
		for _, alias := range append([]string{entry.Name}, entry.Aliases...) {
			key := Normalize(alias) + ":" + Normalize(entry.Equipment)
			if aliases[key] != "" {
				t.Fatal("ambiguous alias", key)
			}
			aliases[key] = entry.ID
		}
		if entry.Video != nil && !videoRE.MatchString(entry.Video.URL) {
			t.Fatal("invalid video URL", entry.ID)
		}
	}
	if Match("Flexao de bracos na parede", "Peso Corporal").ID != "wall-push-up" {
		t.Fatal("alias missing")
	}
	if Match("Flexão na parede", "Máquina") != nil {
		t.Fatal("wrong variant")
	}
}

func TestImportedBodyweightNames(t *testing.T) {
	for _, sample := range [][3]string{{"Prancha", "Livre", "plank"}, {"Flexão de braço", "Peso do corpo", "push-up"}, {"Barra fixa (pegada pronada)", "Peso Corporal", "pull-up"}} {
		entry := Match(sample[0], sample[1])
		if entry == nil || entry.ID != sample[2] || entry.Video == nil {
			t.Fatal("missing reference", sample)
		}
	}
	if Match("Flexão inclinada", "Livre") != nil || Match("Supino reto com barra", "Haltere") != nil {
		t.Fatal("unsafe variant match")
	}
}
