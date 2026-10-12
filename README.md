# Bit Knights Car Rental Database

**CSC312 Database Practical Assignment 2 — Group 8**
University of the Western Cape

| Team member | Student number |
|---|---|
| Ntlahla Kalalo | 4497363 |
| Vutshila Marvin Makhubela | 4335742 |
| Constance Xoliwe Maluleke | 4350565 |
| Andisiwe Mankayi | 4334941 |
| Mthokozisi Junior Nkalanga | 4323080 |

A MySQL 8 relational database for a three-branch car rental company
(Cape Town CBD, Cape Town Airport, Stellenbosch), with 10 business queries,
a Python application that runs them, and an automated test script.

**GitHub repository:** https://github.com/MarvinVutshila/BitKnights-CarRental-Database

---

## Project files

| File | Purpose |
|---|---|
| `01_schema.sql` | Creates the database, 7 tables in 3NF, all constraints, the trigger for the derived `Rental_Cost`, and indexes. |
| `02_sample_data.sql` | Loads realistic Western Cape sample data. `Rental_Cost` is filled automatically by the trigger. |
| `03_queries.sql` | The 10 business queries (2 simple, 4 medium, 4 complex). Each is marked with a `### Qn` header so the Python script can split them. |
| `car_rental_app.py` | Connects to MySQL, builds the database (`--setup`), runs all 10 queries, and demonstrates a parameterised query and constraint error handling. |
| `test_database.py` | Automated validation tests for constraints, the trigger and cascade behaviour. Every test is rolled back, so sample data is never changed. |
| `requirements.txt` | Python dependencies (`mysql-connector-python`, `python-dotenv`). |
| `.env.example` | Template for the connection settings; copy to `.env` and fill in your MySQL password. |
| `The_Bit_Knights_Practical_2.docx` | Written report (scenario, ERD, normalisation, implementation, queries, testing, reflections). |
| `screenshots/` | Figures used in the report: the ERD, each table after data insertion, the Python output, and the test run. |

---

## Requirements

- **Python 3.8+**
- **MySQL Server 8.0.16 or later** (CHECK constraints are only enforced from 8.0.16)
- Python packages: `mysql-connector-python`, `python-dotenv`

---

## How to run

```bash
# 1. Install the Python dependencies
pip install -r requirements.txt

# 2. Create your local .env from the template and add your MySQL password
#    Windows:
copy .env.example .env
#    macOS / Linux:
#    cp .env.example .env

# 3. Build the database, load the sample data, and run the 10 queries
python car_rental_app.py --setup

# 4. On later runs, just execute the queries
python car_rental_app.py

# 5. Run the automated validation tests
python test_database.py