-- Functions for performance tests

CREATE OR REPLACE FUNCTION insert_random_artists(num_artists INT)
RETURNS VOID AS $$
DECLARE
    i INT;
    random_name VARCHAR(255);
    random_nickname VARCHAR(255);
BEGIN
    FOR i IN 1..num_artists LOOP
        random_name := 'Artist ' || i;
        random_nickname := 'Nick ' || i;

        INSERT INTO t_artist (name, nickname)
        VALUES (random_name, random_nickname);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_random_creations(num_creations INT)
RETURNS VOID AS $$
DECLARE
    i INT;
    random_artist_id UUID;
    random_name VARCHAR(255);
    random_acl ace_uuid[];
BEGIN
    FOR i IN 1..num_creations LOOP
        -- Select a random existing artist id
        SELECT id INTO random_artist_id FROM t_artist ORDER BY RANDOM() LIMIT 1;

        random_name := 'Creation ' || i;
        random_acl := '{a//' || random_artist_id || '=rw}';

        INSERT INTO t_creation (id, artist_id, name, acl)
        VALUES (i, random_artist_id, random_name, random_acl);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_artists_and_creations(num_artists INT, num_creations INT)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    i INT;
    random_name VARCHAR(255);
    random_nickname VARCHAR(255);
    random_artist_id UUID;
    random_acl ace_uuid[];
BEGIN
    start_time := clock_timestamp();
    FOR i IN 1..num_artists LOOP
        random_name := 'Artist ' || i;
        random_nickname := 'Nick ' || i;
        INSERT INTO t_artist (name, nickname) VALUES (random_name, random_nickname);
    END LOOP;
    end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to insert artists: % milliseconds', EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;

    start_time := clock_timestamp();
    FOR i IN 1..num_creations LOOP
        -- Select a random existing artist id
        SELECT id INTO random_artist_id FROM t_artist ORDER BY RANDOM() LIMIT 1;

        random_name := 'Creation ' || i;
        random_acl := '{a//' || random_artist_id || '=rw}';
        RAISE NOTICE 'acl %', random_acl;

        INSERT INTO t_creation (id, artist_id, name, acl)
        VALUES (i, random_artist_id, random_name, ('{a//' || random_artist_id || '=rw}')::ace_uuid[]);
    END LOOP;
    end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to insert creations: % milliseconds', EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance_test_query1(random_artist_id UUID)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    PERFORM * FROM t_creation WHERE artist_id = random_artist_id;
    PERFORM * FROM t_creation WHERE artist_id = random_artist_id;
    PERFORM * FROM t_creation WHERE artist_id = random_artist_id;
    end_time := clock_timestamp();
    RAISE NOTICE 'Time taken for standard WHERE query: % milliseconds', EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION performance_test_query2(random_artist_id TEXT)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    SET LOCAL app_user.uuid = 'e8cda5da-1687-40ab-8db9-b8f0f9ba4c58';
    start_time := clock_timestamp();
    PERFORM * FROM t_creation;
    PERFORM * FROM t_creation;
    PERFORM * FROM t_creation;
    end_time := clock_timestamp();
    RAISE NOTICE 'Time taken for ACL query: % milliseconds', EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
END;
$$ LANGUAGE plpgsql;
