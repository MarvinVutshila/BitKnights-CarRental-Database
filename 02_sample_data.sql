/*
  Team Name   : The Bit Knights (Group 8)
  File        : 02_sample_data.sql
  Purpose     : Loads realistic Cape Town sample data. Rental_Cost is filled by the trigger.
*/
USE bit_knights_car_rental;

INSERT INTO Company (Company_Name, Company_Contacts, Company_Address) VALUES
('Bit Knights Cape Town CBD',  '021 555 0101', '12 Strand Street, Cape Town, 8001'),
('Bit Knights Cape Town Airport', '021 555 0102', 'Airport Approach Road, Matroosfontein, 7490'),
('Bit Knights Stellenbosch',   '021 555 0103', '45 Dorp Street, Stellenbosch, 7600');

INSERT INTO Employee (Company_ID, Employee_First_Name, Employee_Last_Name, Employee_Job_Title) VALUES
(1, 'Thandi',  'Nkosi',    'Branch Manager'),
(1, 'Pieter',  'van Wyk',  'Rental Agent'),
(1, 'Aisha',   'Davids',   'Rental Agent'),
(2, 'Sipho',   'Dlamini',  'Branch Manager'),
(2, 'Megan',   'Jacobs',   'Rental Agent'),
(2, 'Liam',    'Petersen', 'Rental Agent'),
(3, 'Zanele',  'Mokoena',  'Branch Manager'),
(3, 'Johan',   'Botha',    'Rental Agent');

INSERT INTO Customer (First_Name, Last_Name, Customer_License) VALUES
('Ayanda', 'Khumalo',    'WC7001245'),
('Fatima', 'Adams',      'WC7002318'),
('Michael','Smith',      'WC7003452'),
('Naledi', 'Mahlangu',   'GP7004871'),
('Ruan',   'du Plessis', 'WC7005693'),
('Chloe',  'Williams',   'EC7006127'),
('Thabo',  'Molefe',     'GP7007740'),
('Sarah',  'Johnson',    'WC7008356'),
('Mandla', 'Zulu',       'KZ7009912'),
('Emma',   'Roberts',    'WC7010284');

INSERT INTO Customer_Contact (Customer_ID, Contact_No, Contact_Type, Contact_Value) VALUES
(1, 1, 'Phone', '082 555 1001'), (1, 2, 'Email', 'ayanda.khumalo@example.co.za'),
(2, 1, 'Phone', '083 555 1002'), (2, 2, 'Email', 'fatima.adams@example.co.za'),
(3, 1, 'Phone', '084 555 1003'),
(4, 1, 'Phone', '071 555 1004'), (4, 2, 'Email', 'naledi.m@example.co.za'),
(5, 1, 'Email', 'ruan.dp@example.co.za'),
(6, 1, 'Phone', '072 555 1006'), (6, 2, 'Phone', '021 555 1066'),
(7, 1, 'Phone', '073 555 1007'), (7, 2, 'Email', 'thabo.molefe@example.co.za'),
(8, 1, 'Phone', '074 555 1008'),
(9, 1, 'Phone', '079 555 1009'), (9, 2, 'Email', 'mandla.zulu@example.co.za'),
(10,1, 'Email', 'emma.roberts@example.co.za');

INSERT INTO Car (Company_ID, Car_Registration, Car_Manufacturer, Car_Model, Car_DailyRate, Car_Status) VALUES
(1, 'CA 123 456', 'Toyota',        'Corolla',      450.00, 'Available'),
(1, 'CA 234 567', 'Volkswagen',    'Polo',         380.00, 'Available'),
(1, 'CA 345 678', 'Toyota',        'Fortuner',     950.00, 'Rented'),
(1, 'CA 456 789', 'Ford',          'Ranger',       900.00, 'Available'),
(2, 'CY 111 222', 'Hyundai',       'i20',          350.00, 'Available'),
(2, 'CY 222 333', 'Kia',           'Seltos',       620.00, 'Rented'),
(2, 'CY 333 444', 'Toyota',        'Hilux',        920.00, 'Maintenance'),
(2, 'CY 444 555', 'Suzuki',        'Swift',        330.00, 'Available'),
(3, 'CL 555 666', 'BMW',           '3 Series',    1300.00, 'Available'),
(3, 'CL 666 777', 'Mercedes Benz', 'C200',        1450.00, 'Available'),
(3, 'CL 777 888', 'Volkswagen',    'T Roc',        700.00, 'Available'),
(3, 'CL 888 999', 'Renault',       'Kwid',         290.00, 'Available');

INSERT INTO Booking (Customer_ID, Employee_ID, Pick_Up_Date, Return_Date, Booking_Status) VALUES
(1, 2, '2026-08-03', '2026-08-07', 'Completed'),
(2, 3, '2026-08-10', '2026-08-12', 'Completed'),
(3, 5, '2026-08-15', '2026-08-22', 'Completed'),
(4, 8, '2026-08-29', '2026-09-01', 'Completed'),
(1, 2, '2026-09-05', '2026-09-08', 'Completed'),
(5, 6, '2026-09-12', '2026-09-19', 'Completed'),
(6, 8, '2026-09-20', '2026-09-24', 'Completed'),
(3, 3, '2026-09-27', '2026-10-01', 'Completed'),
(7, 5, '2026-10-05', '2026-10-15', 'Active'),
(8, 2, '2026-10-10', '2026-10-14', 'Active'),
(2, 6, '2026-10-20', '2026-10-25', 'Confirmed'),
(9, 8, '2026-11-01', '2026-11-05', 'Pending'),
(4, 4, '2026-12-15', '2026-12-30', 'Confirmed'),
(5, 3, '2026-09-10', '2026-09-11', 'Cancelled');

INSERT INTO Rental (Booking_ID, Car_ID, Rental_Status) VALUES
(1, 1,  'Returned'),
(2, 2,  'Returned'),
(3, 5,  'Returned'),
(3, 8,  'Returned'),
(4, 11, 'Returned'),
(5, 3,  'Returned'),
(6, 6,  'Returned'),
(6, 7,  'Returned'),
(7, 9,  'Returned'),
(8, 4,  'Returned'),
(9, 6,  'Active'),
(10,3,  'Active'),
(11,5,  'Reserved'),
(12,10, 'Reserved'),
(13,5,  'Reserved'),
(13,8,  'Reserved'),
(14,2,  'Cancelled');
