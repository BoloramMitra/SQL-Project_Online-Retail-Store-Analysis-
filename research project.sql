Create database TATASales;
use TATASales;

Create table Onlineretail(
InvoiceNo int,
StockCode int,
Description text,
Quantity int,
InvoiceDate text,
UnitPrice double,
CustomerID int,
Country text
);


select count(*) from onlineretail
where CustomerID = 0;

select count(*) from onlineretail
where CustomerID <> 0;

select count(*) from onlineretail
where StockCode = 0;

select count(*) from onlineretail
where InvoiceNo = 0;

select count(*) from onlineretail;

ALTER TABLE Onlineretail
ADD COLUMN New_InvoiceDate DATETIME;

set sql_safe_updates = 0;

UPDATE Onlineretail
SET New_InvoiceDate = STR_TO_DATE(InvoiceDate, '%d-%m-%Y %H:%i');

alter table Onlineretail drop column InvoiceDate;

ALTER TABLE Onlineretail
RENAME COLUMN New_InvoiceDate TO InvoiceDate;

Select * from onlineretail limit 100;

UPDATE onlineretail
SET Stockcode = '11111'
WHERE stockcode = 0;

-- Count how many distint stockcodes are there?

SELECT COUNT(DISTINCT StockCode) AS distinct_stockcode_count
FROM Onlineretail;

-- List all distinct stockcodes and show their associated description

SELECT DISTINCT StockCode, Description
FROM Onlineretail;

-- find the top 10 products(stockcode) accross all countries

SELECT StockCode, COUNT(StockCode) AS Countofproducts
FROM Onlineretail
WHERE StockCode IS NOT NULL
GROUP BY StockCode
ORDER BY Countofproducts DESC
LIMIT 10;


-- Find the top 10 distinct products country wise and rank them from 1 to 10, Create a stored procedure for it.

DELIMITER //
CREATE PROCEDURE Top10ProductsCountrywise()
BEGIN
    WITH RankedProducts AS (
        SELECT Country, StockCode,
               ROW_NUMBER() OVER (PARTITION BY Country ORDER BY COUNT(*) DESC) AS ranked
        FROM Onlineretail
        GROUP BY Country, StockCode
    )
    SELECT Country, StockCode, ranked
    FROM RankedProducts
    WHERE ranked <= 10;
END //
DELIMITER ;

call Top10ProductsCountrywise();

-- Group the stockcodes based upon the country, display the total count of distinct stockcodes, countrywise, to find out the diversity in each country

SELECT Country, COUNT(DISTINCT StockCode) AS total_distinct_stocks
FROM Onlineretail
GROUP BY Country
order by total_distinct_stocks DESC;

-- Group the all stockcodes based upon the country, to find out the biggest market

select country, count(stockcode) as total_stocks
from Onlineretail
where Stockcode is not null
group by country
order by total_stocks desc;

-- Find the countries with lowest diversity of stock limit by 10

Select country, count(stockcode) as countofstock
from OnlineRetail
group by country
order by countofstock limit 10;

-- find the least ordered 10 products(stockcode) across all countries

Select StockCode, Count(StockCode) as LeastOrderedItems
from Onlineretail
Where Stockcode is not null
group by stockcode
having LeastOrderedItems between 1 and 10
order by LeastOrderedItems ASC;

-- find top 10 countries with highest customer base rank them as per the customer count

SELECT country, customer_count, ranked_customerbasewise
FROM (SELECT country, 
	  COUNT(CustomerID) AS customer_count,
	  DENSE_RANK() OVER (ORDER BY COUNT(CustomerID) DESC) AS ranked_customerbasewise
	  FROM Onlineretail
      GROUP BY country) AS Ranked
ORDER BY ranked_customerbasewise
LIMIT 10;

-- rank the top 10 items which are ordered in highest quantity

SELECT stockcode, COUNT(stockcode) AS count_of_items, SUM(quantity) AS total_quantity
FROM onlineretail
GROUP BY stockcode
ORDER BY total_quantity DESC
LIMIT 10;

-- check out which day of week the company has generated maximum number of sales

select dayname(InvoiceDate) as Days, count(InvoiceNo) as count_Of_Sales
from onlineretail
group by dayname(InvoiceDate)
order by count(Stockcode) DESC;

-- Check out the top 10 of unique items which are most ordered in weekends (Fri, Sat,Sun), group them accordingly with the item stockcode. Pivot result as 

select stockcode, dayname(InvoiceDate) as Days, count(Stockcode) as counted
from onlineretail
where dayname(InvoiceDate) in ('Saturday', 'Sunday', 'Friday')
group by stockcode,dayname(InvoiceDate)
order by count(Stockcode) DESC;

-- pivotting the result for the better view

SELECT Stockcode, MAX(Sunday) AS Sunday, MAX(Saturday) AS Saturday, MAX(Friday) AS Friday
FROM (SELECT Stockcode,
	  SUM(CASE WHEN DAYNAME(InvoiceDate) = 'Sunday' THEN 1 ELSE 0 END) AS Sunday,
	  SUM(CASE WHEN DAYNAME(InvoiceDate) = 'Saturday' THEN 1 ELSE 0 END) AS Saturday,
      SUM(CASE WHEN DAYNAME(InvoiceDate) = 'Friday' THEN 1 ELSE 0 END) AS Friday
    FROM onlineretail
    GROUP BY Stockcode
) AS subquery
GROUP BY Stockcode
ORDER BY (Sunday+Saturday+Friday) DESC LIMIT 10;

-- Check out the top 10% of unique items which are most ordered in weekends (Fri, Sat,Sun), group them accordingly with the item stockcode.

SELECT Stockcode, Days, counted
FROM (SELECT count(Stockcode) as counted , DAYNAME(InvoiceDate) AS Days, stockcode,
	NTILE(10) OVER(ORDER BY COUNT(Stockcode) DESC) AS percentile_group
    FROM onlineretail
    WHERE DAYNAME(InvoiceDate) IN ('Saturday', 'Sunday', 'Friday')
    GROUP BY Stockcode, Days) AS subquery
WHERE percentile_group = 1 -- Selecting top 10%
GROUP BY Stockcode, Days
ORDER BY COUNT(Stockcode) DESC;

-- which top 10 items caused highest sales, rank them, where sale = (unitprice x quantity)

Select stockcode, round(SUM((UnitPrice*Quantity)),2) as Sales,
Rank() over (order by SUM((UnitPrice*Quantity)) DESC) as ranked_over_Sales
from onlineretail
group by stockcode
limit 10;