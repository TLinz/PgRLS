-- Core database schema definitions, including tables and extensions

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "acl";

CREATE TABLE t_artist (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255),
    nickname VARCHAR(255),
    acl ace_uuid[]
);

CREATE TABLE t_creation (
    id int PRIMARY KEY NOT NULL,
    artist_id UUID,
    name VARCHAR(255),
    acl ace_uuid[]
);

CREATE TABLE t_group (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    parent_id UUID REFERENCES t_group(id)
);

-- Add ACL column to t_group table
ALTER TABLE t_group
ADD COLUMN acl ace[] DEFAULT '{}'::ace[]; -- Assuming acl column will have an array of ACLs, initialized as empty array

CREATE TABLE t_user_group (
    user_id UUID NOT NULL,
    group_id UUID NOT NULL,
    PRIMARY KEY (user_id, group_id),
    FOREIGN KEY (user_id) REFERENCES t_artist(id),
    FOREIGN KEY (group_id) REFERENCES t_group(id)
);

ALTER TABLE t_creation ADD CONSTRAINT fk_artist
FOREIGN KEY (artist_id)
REFERENCES t_artist(id);

ALTER TABLE t_creation ENABLE ROW LEVEL SECURITY;

ALTER TABLE t_creation ADD COLUMN extracted_uuids UUID[];

UPDATE t_creation
SET extracted_uuids = array(
    SELECT unnest(regexp_matches(acl::text, '[a-f0-9-]{36}', 'g'))::UUID
);

CREATE INDEX idx_extracted_uuids ON t_creation USING GIN (extracted_uuids);

CREATE INDEX idx_artist_id ON t_creation (artist_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON t_creation TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON t_artist TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON t_group TO PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON t_user_group TO PUBLIC;

CREATE POLICY creation_read_policy ON t_creation FOR SELECT TO PUBLIC
USING (t_creation.extracted_uuids && ARRAY[current_setting('app_user.uuid')::UUID]
           AND acl_check_access(acl, 'r'::text, ARRAY[current_setting('app_user.uuid')::UUID], false) = 'r');

CREATE POLICY creation_add_policy ON t_creation FOR INSERT TO PUBLIC
WITH CHECK (artist_id = current_setting('app_user.uuid')::UUID);

CREATE POLICY creation_update_policy on t_creation FOR UPDATE TO PUBLIC
USING (acl_check_access(acl, 'w'::text, ARRAY[current_setting('app_user.uuid')::UUID], false) = 'w')
WITH CHECK (artist_id = current_setting('app_user.uuid')::UUID);