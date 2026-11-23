package app

import "testing"

func TestOptionalRewardPrivacy(t *testing.T) {
	e := newEnv(t)
	a, b, c := e.register("reward-a"), e.register("reward-b"), e.register("reward-c")
	e.newGroup("Squad", a, b)
	e.newGroup("Other", c)
	snapshot := map[string]any{"records": []any{map[string]any{"id": "weeks:10", "title": "Ritmo constante", "detail": "10 semanas ativas", "kind": "weeks", "value": "10", "at": "2026-11-22T12:00:00Z", "seen": true}}, "pinned": "weeks:10", "visible_to_squads": false}
	if status, _ := e.do("PUT", "/v1/me/rewards", a.token, snapshot); status != 200 {
		t.Fatal(status)
	}
	if status, _ := e.do("GET", "/v1/members/"+a.id+"/showcase", b.token, nil); status != 404 {
		t.Fatal("private snapshot exposed", status)
	}
	if _, body := e.do("GET", "/v1/me/rewards", b.token, nil); body["snapshot"] != nil {
		t.Fatal("other user's backup exposed")
	}
	snapshot["visible_to_squads"] = true
	if status, _ := e.do("PUT", "/v1/me/rewards", a.token, snapshot); status != 200 {
		t.Fatal(status)
	}
	if status, body := e.do("GET", "/v1/members/"+a.id+"/showcase", b.token, nil); status != 200 || body["pinned"] == nil || body["records"] != nil {
		t.Fatal("wrong public view", status, body)
	}
	if status, _ := e.do("GET", "/v1/members/"+a.id+"/showcase", c.token, nil); status != 404 {
		t.Fatal("other group saw showcase", status)
	}
	if status, _ := e.do("POST", "/v1/groups/me/leave", b.token, nil); status != 204 {
		t.Fatal(status)
	}
	if status, _ := e.do("GET", "/v1/members/"+a.id+"/showcase", b.token, nil); status != 404 {
		t.Fatal("former member retained access")
	}
	if status, _ := e.do("DELETE", "/v1/me/rewards", a.token, nil); status != 204 {
		t.Fatal(status)
	}
	if _, body := e.do("GET", "/v1/me/rewards", a.token, nil); body["snapshot"] != nil {
		t.Fatal("backup not removed")
	}
	if status, _ := e.do("GET", "/v1/me/rewards", "", nil); status != 401 {
		t.Fatal("missing authentication", status)
	}
	snapshot["pinned"] = "missing"
	if status, _ := e.do("PUT", "/v1/me/rewards", a.token, snapshot); status != 422 {
		t.Fatal("unknown pinned reward accepted", status)
	}
}
