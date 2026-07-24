"""
Adds a user_id column to the ingredients table for per-user pantry scoping.

Existing rows are left with user_id = NULL — treated as orphaned/legacy
data. They are never returned to any user (every query filters by an exact
user_id match, which NULL never satisfies), since there's no reliable way
to know which Supabase account they originally belonged to. They still
exist in the database and can be manually reassigned with a one-off UPDATE
if you want to recover them into a specific real account later.

Safe to re-run — skips if the column already exists.

Run: venv/Scripts/python.exe scripts/migrate_add_user_id.py
"""

import os
import sqlite3

DB_PATH = os.path.join(os.path.dirname(__file__), "..", "fridge2table.db")


def main():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("PRAGMA table_info(ingredients)")
    columns = [row[1] for row in cur.fetchall()]

    if "user_id" in columns:
        print("user_id column already exists — nothing to do.")
        conn.close()
        return

    cur.execute("ALTER TABLE ingredients ADD COLUMN user_id TEXT")
    conn.commit()

    cur.execute("SELECT COUNT(*) FROM ingredients")
    orphaned_count = cur.fetchone()[0]

    print("Added user_id column to ingredients.")
    print(f"{orphaned_count} existing row(s) now have user_id = NULL (orphaned, hidden from all users).")
    conn.close()


if __name__ == "__main__":
    main()
