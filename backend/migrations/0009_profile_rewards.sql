CREATE TABLE profile_rewards (
 user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
 snapshot TEXT NOT NULL,
 visible_to_squads INTEGER NOT NULL DEFAULT 0 CHECK(visible_to_squads IN (0,1)),
 updated_at INTEGER NOT NULL
);
