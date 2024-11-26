-- ACL logic functions

--
-- Modifies the ACL for a creation in t_creation based on the associated artist's ACL.
-- Sets the creation's ACL to NULL if the artist has no ACL, or merges it with the new ACL.
--
CREATE OR REPLACE FUNCTION creation_modify()
RETURNS TRIGGER AS $$
DECLARE
  v_parent_acl ace_uuid[];
BEGIN
--   raise notice 'new artist id is %', NEW.artist_id;
  v_parent_acl = (SELECT p.acl FROM t_artist p WHERE p.id = NEW.artist_id);
--   raise notice 'new artist parent acl is %', v_parent_acl;
  IF NEW.acl IS NULL THEN
    NEW.acl = v_parent_acl;
  ELSE
    NEW.acl = acl_merge(v_parent_acl, NEW.acl, true, true);
--     raise notice 'new artist new acl is %', NEW.acl;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--
-- Get all of the groups that a certain user belongs to.
-- Redundancy in 't_user_group' to improve perf.
--
CREATE OR REPLACE FUNCTION get_user_groups(user_uuid UUID)
RETURNS UUID[] AS $$
DECLARE
    group_uuids UUID[];
BEGIN
    SELECT ARRAY_AGG(group_id) INTO group_uuids
    FROM t_user_group
    WHERE user_id = user_uuid;

    RETURN group_uuids;
END;
$$ LANGUAGE plpgsql;

--
-- Check whether a user can access certain records based on both acl in user and group table.
--
CREATE OR REPLACE FUNCTION acl_check_access_groups(
    acl ACE_UUID[],
    permission CHAR,
    user_uuid UUID,
    group_uuids UUID[])
RETURNS CHAR AS $$
DECLARE
    result CHAR;
    gid CHAR;
BEGIN
    result := acl_check_access(acl, permission, ARRAY[user_uuid], false);
    IF result = permission THEN
        RETURN result;
    END IF;

    IF group_uuids IS NOT NULL AND array_length(group_uuids, 1) > 0 THEN
        FOREACH gid IN ARRAY group_uuids LOOP
            result := acl_check_access(acl, permission, ARRAY[gid], false);
--             raise notice 'user group: %', gid;
            IF result = permission THEN
                RETURN result;
            END IF;
        END LOOP;
    END IF;

    RETURN 'n';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION update_user_group_hierarchy()
RETURNS TRIGGER AS $$
DECLARE
    v_group_id UUID;
    v_parent_id UUID;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_group_id := NEW.group_id;
        LOOP
            SELECT parent_id INTO v_parent_id FROM t_group WHERE id = v_group_id;
            EXIT WHEN v_parent_id IS NULL;

            INSERT INTO t_user_group (user_id, group_id)
            VALUES (NEW.user_id, v_parent_id)
            ON CONFLICT (user_id, group_id) DO NOTHING;

            v_group_id := v_parent_id;
        END LOOP;

    -- Deletion operations are not synchronized.
    -- Deletion cascade operations may lead to accidental deletion
    -- because a parent group may have multiple subgroups.

--     ELSIF TG_OP = 'DELETE' THEN
--         v_group_id := OLD.group_id;
--         LOOP
--             SELECT parent_id INTO v_parent_id FROM t_group WHERE id = v_group_id;
--             EXIT WHEN v_parent_id IS NULL;
--
--             DELETE FROM t_user_group
--             WHERE user_id = OLD.user_id AND group_id = v_parent_id
--             AND NOT EXISTS (
--                 SELECT 1
--                 FROM t_user_group
--                 WHERE user_id = OLD.user_id AND group_id = v_group_id
--             );
--
--             v_group_id := v_parent_id;
--         END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handle_user_deletion()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM t_user_group WHERE user_id = OLD.id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;