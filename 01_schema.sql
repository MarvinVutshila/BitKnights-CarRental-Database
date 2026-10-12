/*
  Team Name   : The Bit Knights (Group 8)
  Course      : CSC312 Database Practical Assignment 2
  File        : 01_schema.sql
  Purpose     : Creates the Bit Knights Car Rental database (3NF) with all constraints.
  Students    : Ntlahla Kalalo (4497363), Vutshila Marvin Makhubela (4335742),
                Constance Xoliwe Maluleke (4350565), Andisiwe Mankayi (4334941),
                Mthokozisi Junior Nkalanga (4323080)
*/

DROP DATABASE IF EXISTS bit_knights_car_rental;
CREATE DATABASE bit_knights_car_rental CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE bit_knights_car_rental;

/* 1. COMPANY : a rental company or branch that owns cars and employs staff (strong entity) */
CREATE TABLE Company (
    Company_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Company_Name     VARCHAR(100) NOT NULL UNIQUE,
    Company_Contacts VARCHAR(20)  NOT NULL,
    Company_Address  VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

/* 2. EMPLOYEE : staff member working for exactly one company (strong entity) */
CREATE TABLE Employee (
    Employee_ID         INT AUTO_INCREMENT PRIMARY KEY,
    Company_ID          INT          NOT NULL,
    Employee_First_Name VARCHAR(50)  NOT NULL,
    Employee_Last_Name  VARCHAR(50)  NOT NULL,
    Employee_Job_Title  VARCHAR(50)  NOT NULL,
    CONSTRAINT fk_employee_company FOREIGN KEY (Company_ID)
        REFERENCES Company (Company_ID) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* 3. CUSTOMER : a person who rents cars (strong entity) */
CREATE TABLE Customer (
    Customer_ID      INT AUTO_INCREMENT PRIMARY KEY,
    First_Name       VARCHAR(50) NOT NULL,
    Last_Name        VARCHAR(50) NOT NULL,
    Customer_License VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB;

/* 4. CUSTOMER_CONTACT : holds the multivalued attribute Customer_Contacts (weak entity).
      Partial key Contact_No together with Customer_ID forms the composite primary key. */
CREATE TABLE Customer_Contact (
    Customer_ID   INT          NOT NULL,
    Contact_No    TINYINT      NOT NULL,
    Contact_Type  ENUM('Phone','Email') NOT NULL,
    Contact_Value VARCHAR(100) NOT NULL,
    PRIMARY KEY (Customer_ID, Contact_No),
    CONSTRAINT fk_contact_customer FOREIGN KEY (Customer_ID)
        REFERENCES Customer (Customer_ID) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

/* 5. CAR : a vehicle owned by one company (strong entity) */
CREATE TABLE Car (
    Car_ID           INT AUTO_INCREMENT PRIMARY KEY,
    Company_ID       INT           NOT NULL,
    Car_Registration VARCHAR(15)   NOT NULL UNIQUE,
    Car_Manufacturer VARCHAR(50)   NOT NULL,
    Car_Model        VARCHAR(50)   NOT NULL,
    Car_DailyRate    DECIMAL(8,2)  NOT NULL,
    Car_Status       ENUM('Available','Rented','Maintenance') NOT NULL DEFAULT 'Available',
    CONSTRAINT chk_car_rate CHECK (Car_DailyRate > 0),
    CONSTRAINT fk_car_company FOREIGN KEY (Company_ID)
        REFERENCES Company (Company_ID) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* 6. BOOKING : a reservation made by a customer and captured by an employee (strong entity) */
CREATE TABLE Booking (
    Booking_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Customer_ID    INT  NOT NULL,
    Employee_ID    INT  NOT NULL,
    Pick_Up_Date   DATE NOT NULL,
    Return_Date    DATE NOT NULL,
    Booking_Status ENUM('Pending','Confirmed','Active','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
    CONSTRAINT chk_booking_dates CHECK (Return_Date >= Pick_Up_Date),
    CONSTRAINT fk_booking_customer FOREIGN KEY (Customer_ID)
        REFERENCES Customer (Customer_ID) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_booking_employee FOREIGN KEY (Employee_ID)
        REFERENCES Employee (Employee_ID) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* 7. RENTAL : bridge (composite) entity that resolves the many to many relationship
      between Booking and Car. Rental_ID is a surrogate primary key and the pair
      (Booking_ID, Car_ID) is kept UNIQUE so a car cannot be listed twice on one booking. */
CREATE TABLE Rental (
    Rental_ID     INT AUTO_INCREMENT PRIMARY KEY,
    Booking_ID    INT NOT NULL,
    Car_ID        INT NOT NULL,
    Rental_Cost   DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    Rental_Status ENUM('Reserved','Active','Returned','Cancelled') NOT NULL DEFAULT 'Reserved',
    CONSTRAINT uq_rental_booking_car UNIQUE (Booking_ID, Car_ID),
    CONSTRAINT chk_rental_cost CHECK (Rental_Cost >= 0),
    CONSTRAINT fk_rental_booking FOREIGN KEY (Booking_ID)
        REFERENCES Booking (Booking_ID) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_rental_car FOREIGN KEY (Car_ID)
        REFERENCES Car (Car_ID) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* DERIVED ATTRIBUTE : Rental_Cost = number of rental days x daily rate (minimum one day).
   The trigger calculates it automatically and stores it as a price snapshot, so later rate
   changes do not rewrite history. */
CREATE TRIGGER trg_rental_cost_before_insert
BEFORE INSERT ON Rental
FOR EACH ROW
SET NEW.Rental_Cost =
    (SELECT GREATEST(DATEDIFF(b.Return_Date, b.Pick_Up_Date), 1) * c.Car_DailyRate
       FROM Booking b, Car c
      WHERE b.Booking_ID = NEW.Booking_ID AND c.Car_ID = NEW.Car_ID);

/* Helpful indexes for the foreign keys used most in joins */
CREATE INDEX idx_booking_dates ON Booking (Pick_Up_Date, Return_Date);
CREATE INDEX idx_car_status    ON Car (Car_Status);