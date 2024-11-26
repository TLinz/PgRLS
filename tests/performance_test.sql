-- Performance test script

BEGIN;
SET ROLE linz;
SELECT insert_artists_and_creations(10, 100000);
END;

SELECT id FROM t_artist ORDER BY RANDOM() LIMIT 1;

BEGIN;
SET ROLE linz;
EXPLAIN ANALYZE
SELECT * FROM t_creation WHERE artist_id = 'e8cda5da-1687-40ab-8db9-b8f0f9ba4c58';
COMMIT;

BEGIN;
SET ROLE app_user;
SET LOCAL app_user.uuid = 'e8cda5da-1687-40ab-8db9-b8f0f9ba4c58';
EXPLAIN ANALYZE
SELECT * FROM t_creation;
COMMIT;

CREATE INDEX idx_artist_id ON t_creation (artist_id);


BEGIN;
SET ROLE linz;
SELECT performance_test_query1('a389a81e-9f3c-49b6-bfa9-a8fe9cd397ea');
COMMIT;

BEGIN;
SET ROLE app_user;
SELECT performance_test_query2('a389a81e-9f3c-49b6-bfa9-a8fe9cd397ea');
COMMIT;
