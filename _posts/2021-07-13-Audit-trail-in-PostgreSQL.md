---
layout: post
title: "Audit trail in PostgreSQL"
---

6 months or so ago I was building an app that required implementing an audit trail in a PostgreSQL database. At the time I had almost no experience with SQL, so I struggled a bit to find what ended up being quite a simple solution. During this struggle I could not find online almost any resources about what I thought was a common problem, so I'll share what I got.


I was building a web app that would allow a small group of internal users to do CRUD like operations safely on a PostgreSQL database. These users had to be able to search, create, change and delete results in some of the database tables just by opening a web page, authenticating, looking through lists and clicking a few buttons buttons.

One fundamental requirement was an audit trail. The database should have a new "audit" table where all the changes made to the other tables using this web app had to be registered.
More specifically, the state of each row before and after the change, as well as the user id of whoever was using the app.


At the time I struggled with two things:

First, I only had access to the user id at the application level, and only had access to the state of the rows at the database level. It was not easy in the backend to know how each row being changed was before the change happened, and I couldn't figure out how the the database could know what was the right user id for each individual query.
Second, the database was used by other services and I only wanted the audit to happen when the data was changed by this app.

Trying to solve this I tried a lot of different ideas, some of them more sensible than others, until after long googling sessions finally finding the key to solve both problems:

```SQL
SET LOCAL audit.userId TO '123';
```

PostgreSQL allows to set custom variables at any time by querying the database. This means the backend can tell the database which user is doing what by setting a custom var with the user id. Furthermore the var can be set locally inside a transaction so it only changes value for operations happening inside that transaction. Because other services won't be using this var, their changes won't be audited, and because I can wrap all queries from this app inside a transaction, concurrent requests to the database will still register the right user id.


So here is a possible minimal implementation for the problem:

Start by creating the audit table in the database
```SQL
CREATE TABLE audit
(
    id serial PRIMARY KEY,
    userId int NOT NULL,
    stateBefore json,
    stateAfter json,
    FOREIGN KEY (userId) REFERENCES <users_table> (id)
);
```
The user id field references the user record in the proper table and the states of the rows are converted and saved as json.

Then create the function that will be called by the trigger:

```SQL
CREATE OR REPLACE FUNCTION audit_trigger()
    RETURNS TRIGGER AS $audit_trigger$
DECLARE
    uid integer;
BEGIN
    uid := current_setting('audit.userId', true)::integer;
    IF EXISTS (SELECT id FROM <users_table> WHERE id = uid) THEN
        IF (TG_OP = 'INSERT') THEN
            INSERT INTO audit (userId, stateBefore, stateAfter) 
            VALUES (uid, NULL, row_to_json(NEW));
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO audit (userId, stateBefore, stateAfter) 
            VALUES (uid, row_to_json(OLD), row_to_json(NEW));
        ELSIF (TG_OP = 'DELETE') THEN
            INSERT INTO audit (userId, stateBefore, stateAfter) 
            VALUES (uid, row_to_json(OLD), NULL);
            RETURN OLD;
        END IF;
    END IF;
    RETURN NEW;
END; 
$audit_trigger$ LANGUAGE plpgsql;
```

This function reads the user id from the custom var and the state of the affected rows before and after the change, then it uses this information to create the proper records in the "audit" table. If the userId does not correspond to a valid user, the function doesn't do anything.

Now apply the trigger to every table that needs auditing.

```SQL
CREATE TRIGGER internal_user_audit
    BEFORE UPDATE OR INSERT OR DELETE
    ON <table_name>
    FOR EACH ROW
    EXECUTE PROCEDURE dashboard_audit();
```

Finally in the backend wrap every query inside a transaction and set the right userId in the beginning.


```SQL
BEGIN;
    SET LOCAL audit.userId TO <user_id>;
    -- query here
COMMIT;
```

And that's it. Quite simple. An audit trail for PostgreSQL using one trigger function and one custom variable.
