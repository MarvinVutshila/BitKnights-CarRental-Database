"""
Team Name    : The Bit Knights (Group 8)
Course       : CSC312 Database Practical Assignment 2
File name    : car_rental_app.py
Team Members :
    - Ntlahla Kalalo (4497363)
    - Vutshila Marvin Makhubela (4335742)
    - Constance Xoliwe Maluleke (4350565)
    - Andisiwe Mankayi (4334941)
    - Mthokozisi Junior Nkalanga (4323080)

Purpose
-------
Connects Python to the MySQL database "bit_knights_car_rental" and
  1. (optional) builds the database from 01_schema.sql and 02_sample_data.sql,
  2. runs all 10 business queries stored in 03_queries.sql and prints the results,
  3. demonstrates a parameterised query and a constraint check with error handling.

Usage
-----
    pip install -r requirements.txt
    python car_rental_app.py --setup     # first run: creates and fills the database
    python car_rental_app.py             # later runs: just executes the queries

Connection details can be changed with the environment variables
DB_HOST, DB_PORT, DB_USER, DB_PASSWORD and DB_NAME.
"""

import os
import re
import sys
from datetime import date
from pathlib import Path

import mysql.connector
from mysql.connector import Error

BASE_DIR = Path(__file__).resolve().parent

# ============================================================================
# CONFIGURATION - LOCAL MYSQL INSTANCE
# ============================================================================
CONFIG = {
    "host": "localhost",           # local computer
    "port": 3306,                  # Default MySQL port
    "user": "root",                # Default local MySQL user
    "password": "",       # <--- Your local MySQL password
}
DB_NAME = os.getenv("DB_NAME", "bit_knights_car_rental")
# ============================================================================


# ----------------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------------
def split_statements(sql_text):
    """Remove /* */ comments and split a SQL script into single statements."""
    sql_text = re.sub(r"/\*.*?\*/", "", sql_text, flags=re.S)
    return [s.strip() for s in sql_text.split(";") if s.strip()]


def run_script(connection, filename):
    """Execute every statement of a .sql file (used by --setup)."""
    cursor = connection.cursor()
    for statement in split_statements((BASE_DIR / filename).read_text(encoding="utf-8")):
        cursor.execute(statement)
    connection.commit()
    cursor.close()
    print(f"  Executed {filename}")


def load_queries(filename="03_queries.sql"):
    """Read the queries file and return a list of (title, sql) pairs."""
    text = (BASE_DIR / filename).read_text(encoding="utf-8")
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    queries = []
    for block in re.split(r"^### ", text, flags=re.M)[1:]:
        title, sql = block.split("\n", 1)
        queries.append((title.strip(), sql.strip().rstrip(";")))
    return queries


def print_table(columns, rows):
    """Print rows as a neat text table."""
    if not rows:
        print("  (no rows returned)")
        return
    data = [[("NULL" if v is None else str(v)) for v in row] for row in rows]
    widths = [max(len(str(c)), *(len(r[i]) for r in data)) for i, c in enumerate(columns)]
    line = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    print(line)
    print("| " + " | ".join(str(c).ljust(w) for c, w in zip(columns, widths)) + " |")
    print(line)
    for r in data:
        print("| " + " | ".join(v.ljust(w) for v, w in zip(r, widths)) + " |")
    print(line)
    print(f"  {len(data)} row(s)")


# ----------------------------------------------------------------------------
# Main tasks
# ----------------------------------------------------------------------------
def setup_database():
    """Create the database, tables, trigger and sample data."""
    print("Setting up the database ...")
    connection = mysql.connector.connect(**CONFIG)
    try:
        run_script(connection, "01_schema.sql")
        run_script(connection, "02_sample_data.sql")
    finally:
        connection.close()


def run_all_queries(connection):
    """Run the 10 queries from 03_queries.sql."""
    passed = 0
    cursor = connection.cursor()
    queries = load_queries()
    for title, sql in queries:
        print(f"\n=== {title} ===")
        try:
            cursor.execute(sql)
            print_table([c[0] for c in cursor.description], cursor.fetchall())
            passed += 1
        except Error as err:
            print(f"  QUERY FAILED: {err}")
    cursor.close()
    print(f"\nSummary: {passed} of {len(queries)} queries executed successfully.")


def demo_parameterised_query(connection, max_rate=500):
    """Parameterised query: protects against SQL injection."""
    print(f"\n=== Extra demo | Available cars costing at most R{max_rate} per day ===")
    cursor = connection.cursor()
    cursor.execute(
        "SELECT Car_Manufacturer, Car_Model, Car_DailyRate FROM Car "
        "WHERE Car_Status = %s AND Car_DailyRate <= %s ORDER BY Car_DailyRate",
        ("Available", max_rate),
    )
    print_table([c[0] for c in cursor.description], cursor.fetchall())
    cursor.close()


def demo_constraint_check(connection):
    """Shows error handling: the CHECK constraint rejects a return date before pick up."""
    print("\n=== Extra demo | Constraint test (return date before pick up date) ===")
    cursor = connection.cursor()
    try:
        cursor.execute(
            "INSERT INTO Booking (Customer_ID, Employee_ID, Pick_Up_Date, Return_Date) "
            "VALUES (%s, %s, %s, %s)",
            (1, 2, date(2026, 11, 10), date(2026, 11, 5)),
        )
        connection.commit()
        print("  Unexpected: the invalid booking was accepted.")
    except Error as err:
        connection.rollback()
        print(f"  Correctly rejected by MySQL: {err.msg}")
    finally:
        cursor.close()


def main():
    try:
        if "--setup" in sys.argv:
            setup_database()
        connection = mysql.connector.connect(database=DB_NAME, **CONFIG)
        print(f"Connected to MySQL database '{DB_NAME}' (server {connection.server_info})")
        try:
            run_all_queries(connection)
            demo_parameterised_query(connection)
            demo_constraint_check(connection)
        finally:
            connection.close()
            print("\nConnection closed.")
    except Error as err:
        print(f"Database error: {err}")
        print("Tip: run 'python car_rental_app.py --setup' and check DB_USER and DB_PASSWORD.")
        sys.exit(1)


if __name__ == "__main__":
    main()