ALTER TABLE tracks ADD COLUMN owner_id TEXT REFERENCES users(id);
CREATE INDEX tracks_owner_idx ON tracks(owner_id);
