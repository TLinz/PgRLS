-- Triggers

CREATE TRIGGER creation_insert
BEFORE INSERT OR UPDATE ON t_creation
FOR EACH ROW EXECUTE PROCEDURE creation_modify();

CREATE TRIGGER trg_update_user_group_hierarchy
AFTER INSERT ON t_user_group
FOR EACH ROW EXECUTE FUNCTION update_user_group_hierarchy();

CREATE TRIGGER trg_handle_user_deletion
AFTER DELETE ON t_artist
FOR EACH ROW EXECUTE FUNCTION handle_user_deletion();