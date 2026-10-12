"""
Team Name    : The Bit Knights (Group 8)
Course       : CSC312 Database Practical Assignment 2
File name    : test_database.py
Team Members :
    - Ntlahla Kalalo (4497363)
    - Vutshila Marvin Makhubela (4335742)
    - Constance Xoliwe Maluleke (4350565)
    - Andisiwe Mankayi (4334941)
    - Mthokozisi Junior Nkalanga (4323080)

Purpose
-------
Automated validation of the bit_knights_car_rental database.
Every test runs inside a transaction that is rolled back afterwards,
so the sample data is never changed.

Usage
-----
    python car_rental_app.py --setup    # build the database first
    python test_database.py
"""

import os
from pathlib import Path

import mysql.connector
from mysql.connector import Error
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

CONFIG = {
    "host":     os.getenv("DB_HOST", "localhost"),
    "port":     int(os.getenv("DB_PORT", 3306)),
    "user":     os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD", ""),
    "database": os.getenv("DB_NAME", "bit_knights_car_rental"),
}

# MySQL error codes (MariaDB uses 4025 for a failed CHECK constraint)
FK_FAIL, FK_PARENT, DUPLICATE, NOT_NULL, BAD_ENUM = 1452, 1451, 1062, 1048, 1265
CHECK_FAIL = (3819, 4025)

results = []


def expect_error(conn, name, sql, params, codes):
    """Run a statement that MUST be rejected with one of the given error codes."""
    codes = codes if isinstance(codes, tuple) else (codes,)
    cur = conn.cursor()
    try:
        cur.execute(sql, params)
        outcome, detail = "FAIL", "statement was accepted"
    except Error as err:
        outcome = "PASS" if err.errno in codes else "FAIL"
        detail = f"error {err.errno}: {err.msg}"[:70]
    finally:
        conn.rollback()
        cur.close()
    results.append((name, outcome, detail))


def expect_value(conn, name, statements, check_sql, expected):
    """Run setup statements, then check that a query returns the expected value."""
    cur = conn.cursor()
    try:
        for sql, params in statements:
            cur.execute(sql, params)
        cur.execute(check_sql)
        actual = cur.fetchone()[0]
        outcome = "PASS" if str(actual) == str(expected) else "FAIL"
        detail = f"expected {expected}, got {actual}"
    except Error as err:
        outcome, detail = "FAIL", f"error {err.errno}: {err.msg}"
    finally:
        conn.rollback()
        cur.close()
    results.append((name, outcome, detail))


def main():
    conn = mysql.connector.connect(**CONFIG)
    conn.autocommit = False

    # ---- Row counts after loading the sample data ----
    for table, rows in [("Company", 3), ("Employee", 8), ("Customer", 10),
                        ("Customer_Contact", 16), ("Car", 12), ("Booking", 14), ("Rental", 17)]:
        expect_value(conn, f"T01 Row count {table}", [], f"SELECT COUNT(*) FROM {table}", rows)

    # ---- Referential integrity ----
    expect_error(conn, "T02 FK: employee for a company that does not exist",
                 "INSERT INTO Employee (Company_ID, Employee_First_Name, Employee_Last_Name, Employee_Job_Title) "
                 "VALUES (%s,%s,%s,%s)", (99, "Test", "User", "Rental Agent"), FK_FAIL)
    # The BEFORE INSERT trigger runs first and finds no car, so Rental_Cost becomes NULL
    # and the NOT NULL rule rejects the row before the foreign key is even checked.
    expect_error(conn, "T03 FK: rental for a car that does not exist",
                 "INSERT INTO Rental (Booking_ID, Car_ID) VALUES (%s,%s)", (1, 999), (FK_FAIL, NOT_NULL))
    expect_error(conn, "T04 ON DELETE RESTRICT: delete a company that owns cars",
                 "DELETE FROM Company WHERE Company_ID = %s", (1,), FK_PARENT)

    # ---- Uniqueness ----
    expect_error(conn, "T05 UNIQUE: duplicate car registration",
                 "INSERT INTO Car (Company_ID, Car_Registration, Car_Manufacturer, Car_Model, Car_DailyRate) "
                 "VALUES (%s,%s,%s,%s,%s)", (1, "CA 123 456", "Toyota", "Yaris", 400), DUPLICATE)
    expect_error(conn, "T06 UNIQUE: duplicate driver's licence",
                 "INSERT INTO Customer (First_Name, Last_Name, Customer_License) VALUES (%s,%s,%s)",
                 ("Copy", "Cat", "WC7001245"), DUPLICATE)
    expect_error(conn, "T07 Bridge UNIQUE (Booking_ID, Car_ID): same car twice on one booking",
                 "INSERT INTO Rental (Booking_ID, Car_ID) VALUES (%s,%s)", (1, 1), DUPLICATE)
    expect_error(conn, "T08 Weak entity PK (Customer_ID, Contact_No) duplicate",
                 "INSERT INTO Customer_Contact VALUES (%s,%s,%s,%s)", (1, 1, "Phone", "000"), DUPLICATE)

    # ---- Domain rules ----
    expect_error(conn, "T09 CHECK: daily rate must be positive",
                 "INSERT INTO Car (Company_ID, Car_Registration, Car_Manufacturer, Car_Model, Car_DailyRate) "
                 "VALUES (%s,%s,%s,%s,%s)", (1, "CA 000 001", "Test", "Neg", -100), CHECK_FAIL)
    expect_error(conn, "T10 CHECK: return date before pick up date",
                 "INSERT INTO Booking (Customer_ID, Employee_ID, Pick_Up_Date, Return_Date) VALUES (%s,%s,%s,%s)",
                 (1, 2, "2026-11-10", "2026-11-05"), CHECK_FAIL)
    expect_error(conn, "T11 ENUM: invalid car status",
                 "UPDATE Car SET Car_Status = %s WHERE Car_ID = %s", ("Stolen", 1), BAD_ENUM)
    expect_error(conn, "T12 NOT NULL: customer without a licence",
                 "INSERT INTO Customer (First_Name, Last_Name, Customer_License) VALUES (%s,%s,%s)",
                 ("No", "Licence", None), NOT_NULL)

    # ---- Derived attribute (trigger) ----
    new_booking = ("INSERT INTO Booking (Booking_ID, Customer_ID, Employee_ID, Pick_Up_Date, Return_Date) "
                   "VALUES (%s,%s,%s,%s,%s)")
    expect_value(conn, "T13 Trigger: 3 days x R290 = R870",
                 [(new_booking, (100, 10, 8, "2026-11-20", "2026-11-23")),
                  ("INSERT INTO Rental (Booking_ID, Car_ID) VALUES (%s,%s)", (100, 12))],
                 "SELECT Rental_Cost FROM Rental WHERE Booking_ID = 100", "870.00")
    expect_value(conn, "T14 Trigger: same day return is charged one day",
                 [(new_booking, (101, 10, 8, "2026-11-20", "2026-11-20")),
                  ("INSERT INTO Rental (Booking_ID, Car_ID) VALUES (%s,%s)", (101, 12))],
                 "SELECT Rental_Cost FROM Rental WHERE Booking_ID = 101", "290.00")
    expect_value(conn, "T15 All stored Rental_Cost values match days x daily rate", [],
                 "SELECT COUNT(*) FROM Rental r JOIN Booking b ON b.Booking_ID = r.Booking_ID "
                 "JOIN Car c ON c.Car_ID = r.Car_ID "
                 "WHERE r.Rental_Cost <> GREATEST(DATEDIFF(b.Return_Date, b.Pick_Up_Date), 1) * c.Car_DailyRate", 0)

    # ---- Cascade on the weak entity ----
    expect_value(conn, "T16 ON DELETE CASCADE removes a customer's contacts",
                 [("DELETE FROM Customer WHERE Customer_ID = %s", (10,))],
                 "SELECT COUNT(*) FROM Customer_Contact WHERE Customer_ID = 10", 0)

    conn.close()

    width = max(len(r[0]) for r in results)
    for name, outcome, detail in results:
        print(f"[{outcome}] {name.ljust(width)}  {detail}")
    passed = sum(r[1] == "PASS" for r in results)
    print(f"\n{passed} of {len(results)} tests passed.")


if __name__ == "__main__":
    main()
