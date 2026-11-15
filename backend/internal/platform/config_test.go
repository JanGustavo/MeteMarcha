package platform

import "testing"

func TestDefaultConfigIsValid(t *testing.T) {
	if err := DefaultConfig().Validate(); err != nil {
		t.Fatal(err)
	}
}

func TestConfigFromEnvironment(t *testing.T) {
	t.Setenv("MM_GROUP_MAX_MEMBERS", "5")
	t.Setenv("MM_STORY_VISIBLE_FOR", "12h")
	t.Setenv("MM_STORY_RECOVERABLE_FOR", "36h")
	c, err := LoadConfig()
	if err != nil {
		t.Fatal(err)
	}
	if c.GroupMaxMembers != 5 || c.StoryVisibleFor.Hours() != 12 || c.StoryRecoverableFor.Hours() != 36 {
		t.Errorf("valores não aplicados: %+v", c)
	}
}

func TestConfigRejectsBadValues(t *testing.T) {
	cases := map[string]map[string]string{
		"número inválido":       {"MM_GROUP_MAX_MEMBERS": "dez"},
		"duração inválida":      {"MM_STORY_VISIBLE_FOR": "um dia"},
		"72h menor que 24h":     {"MM_STORY_VISIBLE_FOR": "48h", "MM_STORY_RECOVERABLE_FOR": "24h"},
		"limite de roda zerado": {"MM_GROUP_MAX_MEMBERS": "0"},
	}
	for name, env := range cases {
		t.Run(name, func(t *testing.T) {
			for k, v := range env {
				t.Setenv(k, v)
			}
			if _, err := LoadConfig(); err == nil {
				t.Error("deveria recusar a configuração")
			}
		})
	}
}
