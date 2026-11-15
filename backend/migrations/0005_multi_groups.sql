-- Preserva as associações do piloto e permite que uma pessoa participe de
-- várias rodas. O grupo ativo define o contexto dos endpoints legados.
CREATE TABLE group_members_next (
    user_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    group_id  TEXT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    role      TEXT NOT NULL CHECK (role IN ('owner', 'member')),
    joined_at INTEGER NOT NULL,
    PRIMARY KEY (user_id, group_id)
);
INSERT INTO group_members_next (user_id, group_id, role, joined_at)
SELECT user_id, group_id, role, joined_at FROM group_members;
DROP TABLE group_members;
ALTER TABLE group_members_next RENAME TO group_members;
CREATE INDEX group_members_group_idx ON group_members(group_id);

CREATE TABLE active_groups (
    user_id  TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    group_id TEXT NOT NULL,
    FOREIGN KEY (user_id, group_id) REFERENCES group_members(user_id, group_id) ON DELETE CASCADE
);
INSERT INTO active_groups (user_id, group_id)
SELECT user_id, group_id FROM group_members;
