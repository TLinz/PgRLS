BEGIN;
SET LOCAL app_user.uuid = '314d6bee-42a0-4254-a00d-7362c793a897';
INSERT INTO t_creation(id, artist_id, name, acl) values
    (0, '314d6bee-42a0-4254-a00d-7362c793a897', 'Happy Life', '{a//314d6bee-42a0-4254-a00d-7362c793a897=w}');
INSERT INTO t_creation(id, artist_id, name, acl) values
    (1, '314d6bee-42a0-4254-a00d-7362c793a897', 'Sad Life', '{a//314d6bee-42a0-4254-a00d-7362c793a897=dw}');
COMMIT;