
SELECT * FROM Customer; --View entire customer table all rows
SELECT * FROM Transactions; --View entire transaction table all rows
SELECT * FROM prod_cat_info; --View entire prod_cat_info table all rows

-- DATA PREPARATION AND UNDERSTANDING


--1: What is the total number of rows in each of the 3 tables in the database?
SELECT 'Customer' AS [Table Name], COUNT(*) as [Total_Rows] FROM Customer            -- Creating a text with row name and counting customer table rows
UNION ALL
SELECT 'Transactions' AS [Table Name], COUNT(*) as [Total_Rows] FROM Transactions    -- Creating a text with row name and counting transaction table rows
UNION ALL
SELECT 'Prod_Cat_Info' AS [Table Name], COUNT(*) as [Total_Rows] FROM prod_cat_info; -- Creating a text with row name and counting prod_cat_info table rows


--2: What is the total number of transactions that have a return?
SELECT COUNT(Qty) AS [Retunred Transactions] FROM Transactions          --Considering negative Qty are returns
WHERE Qty<0;


--3: As you have noticed, the date provided across the datasets are not in a correct format. As first steps, pls convert the date variables into
--valid date formats before
--Already converted the date datatype in date while uploading


--4:What si the time range of the transactions data available for analysis? Show the output in number of days,months, years simultaneously in different columns. 
SELECT DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) as [Days],        --finding day difference using min date and max date
DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date)) as Months,             --finding month difference using min date and max date
DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) as Years                --finding year difference using min date and max date
FROM Transactions;


--5: Which product category does the sub-category "DIY" belong to?
SELECT prod_cat FROM prod_cat_info
WHERE prod_subcat='DIY';


-- DATA ANALYSIS


--1: Which channels is most frequently used for transactions?
SELECT Store_type FROM 
(SELECT TOP 1 Store_type, COUNT(transaction_id) as [Channel Count] FROM Transactions  --Using this query as table to select one store based on cound of transactions in descending order 
GROUP BY Store_type
ORDER BY [Channel Count] desc
) as t


--2: What is the count of Male and Female customers in the database?
SELECT Gender, Count(Gender) as Total FROM Customer
WHERE GENDER in ('M', 'F')                                               
GROUP BY Gender


--3: From which city do we have the maximum number of customers and how many?
SELECT TOP 1 city_code, COUNT(customer_Id) as Total FROM Customer
GROUP BY city_code
ORDER BY Total desc


--4: How many sub-categories are there under the Books Category?
SELECT COUNT(prod_subcat) AS [Books Sub-Categories] FROM prod_cat_info
WHERE prod_cat='Books'


--5: What is the maximum quantity of products ever ordered?
SELECT Qty FROM (SELECT Top 1 Qty, COUNT(Qty) as Total FROM Transactions
GROUP BY Qty
ORDER BY Qty desc
) as t


--6: What is net total revenue generated in categories Electronics and Books?
SELECT round(SUM(t.total_amt), 3) AS Total_Revenue FROM Transactions AS t
full join prod_cat_info as p
on t.prod_cat_code=p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code  --Using two columns to create unique on for joining
WHERE p.prod_cat IN ('Electronics', 'Books')


--7: How many customers have >10 transactions with us, exclusing returns?
SELECT COUNT(cust_id) as Customers_Count FROM (
SELECT cust_id, COUNT(transaction_id) as [Number of Transactions] FROM Transactions    --Using Query as table for another select query
WHERE Qty>0
GROUP BY cust_id
) AS t
WHERE [Number of Transactions]>10


--8: What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagships" Stores?
SELECT ROUND(SUM(t.total_amt), 2) as [Total_Revenue] FROM Transactions as t         -- Rounded value upto to two decimal for better presentation
full join prod_cat_info as p
on t.prod_cat_code=p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code 
WHERE t.Store_type='Flagship store' AND (p.prod_cat IN ('Electronics', 'Clothing'))  --Providing filter for store type & product categories


--9: What is total revenue generated from "Male" customers in "Electronics category? Output should display total revenue by prod_sub_cat?
SELECT p.prod_subcat, SUM(t.total_amt) as [Total Revenue] FROM Transactions as t
left join prod_cat_info as p														-- joining prod_cat_info
on t.prod_cat_code=p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code
left join Customer as c
on c.customer_Id=t.cust_id AND t.prod_subcat_code=p.prod_sub_cat_code				-- joining customer table
WHERE p.prod_cat='Electronics' AND c.Gender='M'
GROUP BY p.prod_subcat


--10: What is the percentage of Sales and Returns by product sub category: display only top 5 sub categories in terms of sales?

SELECT Top 5 
p.prod_subcat, CONCAT(ROUND((SUM(TOTAL_AMT)/(SELECT SUM(TOTAL_AMT) FROM Transactions))*100, 3), ' %') as Sales_Percentage,  --Calculating subcategory sales percentage from total sales
CONCAT(ROUND((COUNT(case when t.Qty< 0 then t.Qty else NULL end)/SUM(QTY))*100, 3), ' %') as Return_Percentage				--Calculating subcategory quantities percentage from total quantities
FROM Transactions as t
inner join prod_cat_info as p 
ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code
GROUP BY p.prod_subcat
ORDER BY SUM(TOTAL_AMT) desc


--11: For all customers aged between 25 and 35 years find what is the net total revenue 
--generated by these customers in last 30 days of transactions from max transactions date available in the data?

SELECT t.cust_id, SUM(t.total_amt) as Net_Revenue FROM Transactions as t
WHERE t.cust_id IN (
SELECT c.customer_Id FROM (SELECT *, case when MONTH(DOB)>MONTH(getdate()) then DATEDIFF(year, DOB, GETDATE())-1
			   when day(DOB)>day(getdate()) then DATEDIFF(year, DOB, GETDATE())-1
			   else DATEDIFF(year, DOB, GETDATE())
			   end age
FROM Customer) as c
WHERE age BETWEEN 25 ANd 35)
AND t.tran_date BETWEEN DATEADD(day, -30, (SELECT MAX(tran_date) FROM Transactions)) AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY t.cust_id


--12: Which product category has seen the max value of returns in the last 3 months of transactions?

SELECT top 1 p.prod_cat, SUM(t.total_amt) as [Returns value] FROM Transactions as t
inner join prod_cat_info as p
on t.prod_cat_code=p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code
WHERE t.total_amt<0 AND
t.tran_date BETWEEN DATEADD(month, -3, (select MAX(tran_date) from Transactions)) AND (select MAX(tran_date) from Transactions)
GROUP BY p.prod_cat
Order by 2 desc


--13: Which store-type sells the maximum products: by value of sales amount and by quantity sold?
SELECT top  1 Store_type, SUM(Qty) as Quantity, SUM(total_amt) as Sales FROM Transactions
Group BY Store_type
Having SUM(Qty)>=ALL(SELECT SUM(Qty) FROM Transactions GROUP BY Store_type) 
AND
SUM(total_amt)>=ALL(SELECT SUM(total_amt) FROM Transactions GROUP BY Store_type)


--14: What are the categories for which average revenue is above the overall average.
SELECT p.prod_cat, ROUND(AVG(t.total_amt), 3) as [Average] FROM Transactions as t
inner join prod_cat_info as p
on t.prod_cat_code=p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code
GROUP BY p.prod_cat
Having AVG(t.total_amt)>(SELECT AVG(total_amt) from Transactions)
 


--15: Find the average and total revenue by each subcategory for the categories which are amongst top 5 categories in terms of quantity sold.

SELECT p.prod_cat, p.prod_subcat, ROUND(AVG(t.total_amt), 3) as [Average], ROUND(SUM(t.total_amt), 3) as Total FROM Transactions as t
inner join prod_cat_info as p
on t.prod_cat_code=p.prod_cat_code AND t.prod_subcat_code=p.prod_sub_cat_code
WHERE p.prod_cat IN
(
SELECT top 5 p1.prod_cat FROM Transactions as t1
inner join prod_cat_info as p1
on t1.prod_cat_code=p1.prod_cat_code AND t1.prod_subcat_code=p1.prod_sub_cat_code
GROUP BY p1.prod_cat
ORDER BY SUM(Qty) desc
)
GROUP BY p.prod_cat, p.prod_subcat
ORDER BY p.prod_cat, p.prod_subcat