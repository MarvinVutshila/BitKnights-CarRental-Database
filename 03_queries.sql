/*
  Team Name   : The Bit Knights (Group 8)
  File        : 03_queries.sql
  Purpose     : The 10 business queries (2 simple, 4 medium, 4 complex).
  Each query is separated by a line starting with "### Qn" so the Python script can read it.
*/
USE bit_knights_car_rental;

### Q1 | Simple | Which cars can be rented right now, cheapest first?
SELECT Car_ID, Car_Manufacturer, Car_Model, Car_Registration, Car_DailyRate
FROM Car
WHERE Car_Status = 'Available'
ORDER BY Car_DailyRate ASC;

### Q2 | Simple | Who are our rental agents (string function)?
SELECT Employee_ID,
       CONCAT(Employee_First_Name, ' ', Employee_Last_Name) AS Agent_Name,
       Employee_Job_Title, Company_ID
FROM Employee
WHERE Employee_Job_Title LIKE '%Agent%'
ORDER BY Employee_Last_Name;

### Q3 | Medium | Revenue performance per company (INNER JOIN, SUM, COUNT, AVG, GROUP BY)
SELECT co.Company_Name,
       COUNT(r.Rental_ID)       AS Total_Rentals,
       SUM(r.Rental_Cost)       AS Total_Revenue,
       ROUND(AVG(r.Rental_Cost), 2) AS Average_Rental_Value
FROM Company co
INNER JOIN Car    c  ON c.Company_ID = co.Company_ID
INNER JOIN Rental r  ON r.Car_ID     = c.Car_ID
WHERE r.Rental_Status IN ('Returned', 'Active')
GROUP BY co.Company_ID, co.Company_Name
ORDER BY Total_Revenue DESC;

### Q4 | Medium | Premium cars priced above the fleet average (subquery in WHERE)
SELECT Car_Manufacturer, Car_Model, Car_DailyRate,
       ROUND(Car_DailyRate - (SELECT AVG(Car_DailyRate) FROM Car), 2) AS Above_Average_By
FROM Car
WHERE Car_DailyRate > (SELECT AVG(Car_DailyRate) FROM Car)
ORDER BY Car_DailyRate DESC;

### Q5 | Medium | Booking activity for every customer including those who never booked (LEFT JOIN, COUNT, MAX, CONCAT)
SELECT CONCAT(cu.First_Name, ' ', cu.Last_Name) AS Customer_Name,
       COUNT(b.Booking_ID)  AS Total_Bookings,
       MAX(b.Pick_Up_Date)  AS Latest_Pick_Up
FROM Customer cu
LEFT JOIN Booking b ON b.Customer_ID = cu.Customer_ID
GROUP BY cu.Customer_ID, cu.First_Name, cu.Last_Name
ORDER BY Total_Bookings DESC, Customer_Name;

### Q6 | Medium | Length and cost of bookings starting in September 2026 (date functions, JOIN, SUM, COUNT)
SELECT b.Booking_ID,
       CONCAT(cu.First_Name, ' ', cu.Last_Name) AS Customer_Name,
       MONTHNAME(b.Pick_Up_Date)                AS Pick_Up_Month,
       GREATEST(DATEDIFF(b.Return_Date, b.Pick_Up_Date), 1) AS Days_Booked,
       COUNT(r.Rental_ID)                       AS Cars_On_Booking,
       SUM(r.Rental_Cost)                       AS Booking_Total
FROM Booking b
JOIN Customer cu ON cu.Customer_ID = b.Customer_ID
JOIN Rental   r  ON r.Booking_ID   = b.Booking_ID
WHERE b.Pick_Up_Date BETWEEN '2026-09-01' AND '2026-09-30'
  AND b.Booking_Status <> 'Cancelled'
  AND r.Rental_Status  <> 'Cancelled'
GROUP BY b.Booking_ID, cu.First_Name, cu.Last_Name, b.Pick_Up_Date, b.Return_Date
ORDER BY b.Pick_Up_Date;

### Q7 | Complex | Loyal high value customers (5 table JOIN, GROUP BY, HAVING with AND)
SELECT CONCAT(cu.First_Name, ' ', cu.Last_Name) AS Customer_Name,
       COUNT(DISTINCT b.Booking_ID)            AS Completed_Bookings,
       COUNT(DISTINCT co.Company_ID)           AS Branches_Used,
       SUM(r.Rental_Cost)                      AS Total_Spent
FROM Customer cu
JOIN Booking b  ON b.Customer_ID = cu.Customer_ID
JOIN Rental  r  ON r.Booking_ID  = b.Booking_ID
JOIN Car     c  ON c.Car_ID      = r.Car_ID
JOIN Company co ON co.Company_ID = c.Company_ID
WHERE b.Booking_Status = 'Completed'
  AND r.Rental_Status  = 'Returned'
GROUP BY cu.Customer_ID, cu.First_Name, cu.Last_Name
HAVING COUNT(DISTINCT b.Booking_ID) >= 2 AND SUM(r.Rental_Cost) > 4000
ORDER BY Total_Spent DESC;

### Q8 | Complex | Employees who earned more than the average employee (nested subquery in HAVING)
SELECT CONCAT(e.Employee_First_Name, ' ', e.Employee_Last_Name) AS Employee_Name,
       co.Company_Name,
       COUNT(DISTINCT b.Booking_ID) AS Bookings_Handled,
       SUM(r.Rental_Cost)           AS Revenue_Generated
FROM Employee e
JOIN Company co ON co.Company_ID  = e.Company_ID
JOIN Booking b  ON b.Employee_ID  = e.Employee_ID
JOIN Rental  r  ON r.Booking_ID   = b.Booking_ID
WHERE r.Rental_Status IN ('Returned', 'Active')
GROUP BY e.Employee_ID, e.Employee_First_Name, e.Employee_Last_Name, co.Company_Name
HAVING SUM(r.Rental_Cost) > (
        SELECT AVG(emp_total)
        FROM (SELECT SUM(r2.Rental_Cost) AS emp_total
                FROM Booking b2
                JOIN Rental r2 ON r2.Booking_ID = b2.Booking_ID
               WHERE r2.Rental_Status IN ('Returned', 'Active')
               GROUP BY b2.Employee_ID) AS per_employee)
ORDER BY Revenue_Generated DESC;

### Q9 | Complex | Idle fleet that needs marketing or maintenance review (NOT IN subquery with AND / OR)
SELECT c.Car_ID, co.Company_Name, c.Car_Manufacturer, c.Car_Model,
       c.Car_Status, c.Car_DailyRate
FROM Car c
JOIN Company co ON co.Company_ID = c.Company_ID
WHERE c.Car_ID NOT IN (SELECT r.Car_ID
                         FROM Rental r
                        WHERE r.Rental_Status IN ('Returned', 'Active', 'Reserved'))
   OR (c.Car_Status = 'Maintenance' AND c.Car_DailyRate > 900)
ORDER BY co.Company_Name, c.Car_DailyRate DESC;

### Q10 | Complex | Multi car or high value bookings with the cars listed together (JOINs, GROUP_CONCAT, HAVING with OR)
SELECT b.Booking_ID,
       CONCAT(cu.First_Name, ' ', cu.Last_Name)                       AS Customer_Name,
       CONCAT(e.Employee_First_Name, ' ', e.Employee_Last_Name)       AS Handled_By,
       GROUP_CONCAT(CONCAT(c.Car_Manufacturer, ' ', c.Car_Model)
                    ORDER BY c.Car_DailyRate DESC SEPARATOR ', ')     AS Cars_Booked,
       COUNT(r.Rental_ID)                                             AS Number_Of_Cars,
       SUM(r.Rental_Cost)                                             AS Booking_Total
FROM Booking  b
JOIN Customer cu ON cu.Customer_ID = b.Customer_ID
JOIN Employee e  ON e.Employee_ID  = b.Employee_ID
JOIN Rental   r  ON r.Booking_ID   = b.Booking_ID
JOIN Car      c  ON c.Car_ID       = r.Car_ID
WHERE r.Rental_Status <> 'Cancelled'
GROUP BY b.Booking_ID, cu.First_Name, cu.Last_Name, e.Employee_First_Name, e.Employee_Last_Name
HAVING COUNT(r.Rental_ID) > 1 OR SUM(r.Rental_Cost) > 5000
ORDER BY Booking_Total DESC;