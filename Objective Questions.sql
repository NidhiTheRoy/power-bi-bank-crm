create database bank_crm_db;
use bank_crm_db;

-- Q1. What is the distribution of account balances across different regions?
Select
	g.GeographyLocation as Region,
    Round(SUM(bc.Balance),2) as TotalBalance,
    Round(AVG(bc.Balance),2) as AverageBalance
From bank_churn bc 
Join customerinfo c on c.CustomerId = bc.CustomerId
Join geography g on c.GeographyID = g.GeographyID
Group By g.GeographyLocation
Order By TotalBalance DESC;

-- Q2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
select CustomerId, 
Surname, 
Age, 
GenderID, 
stimatedSalary, 
GeographyID, 
BankDOJ
from (
	select *,
	month(BankDOJ) as MOJ
	from customerinfo
) c
where MOJ in (1,2,3)  
order by EstimatedSalary desc
limit 5;

-- Q3. Calculate the average number of products used by customers who have a credit card. (SQL)
select 
	round(avg(NumOfProducts),2) as AvgNumOfProducts
from bank_churn
where HasCrCard = true;

-- Q4: Determine the churn rate by gender for the most recent year in the dataset
WITH RecentYearData AS (
    SELECT MAX(YEAR(BankDOJ)) AS MostRecentYear
    FROM customerinfo
),
GenderChurn AS (
    SELECT 
        g.GenderCategory AS Gender,
        COUNT(CASE WHEN b.Exited = 1 THEN 1 END) AS ChurnedCustomers,
        COUNT(*) AS TotalCustomers
    FROM bank_churn b
    JOIN customerinfo c ON b.CustomerID = c.CustomerID
    JOIN gender g ON c.GenderID = g.GenderID
    JOIN RecentYearData r ON YEAR(c.BankDOJ) = r.MostRecentYear
    GROUP BY g.GenderCategory
)
SELECT 
    Gender,
    ChurnedCustomers,
    TotalCustomers,
    (ChurnedCustomers / TotalCustomers) * 100 AS ChurnRate
FROM GenderChurn;

-- Q5. Compare the average credit score of customers who have exited and those who remain. (SQL)
Select
	e.ExitID,
    Case
		When e.ExitID = 0 Then 'Retained'
		Else 'Exited'
	End as LoyaltyStatus,
    Round(Avg(b.CreditScore),0) as AvgCreditScore
From exitcustomer e
Left Join bank_churn b on e.ExitID = b.Exited
Group By e.ExitID;

-- Q6. Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)
with RankedSalaries as (
	Select
		g.GenderID as GenderID,
        g.Gendercategory as Gendercategory,
        Round(Avg(c.EstimatedSalary),0) as AvgEstimatedSalary,
        Count(b.IsActiveMember) as CountOfActiveID,
        Rank() OVER (Partition by g.GenderID, g.Gendercategory order by Avg(c.EstimatedSalary) desc) as SalaryRank
	from gender g 
	join customerinfo c on c.GenderID = g.GenderID
	join bank_churn b on b.CustomerID = c.CustomerID
	join activecustomer a on a.ActiveID = b.IsActiveMember
	Group by g.GenderID, g.Gendercategory
)
Select
	Gendercategory,
    AvgEstimatedSalary,
    CountOfActiveID
from RankedSalaries
where SalaryRank = 1
order by AvgEstimatedSalary desc;

-- Q7. Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
Select 
	Case
		When CreditScore between 800 and 850 then 'Excellent'
        When CreditScore between 740 and 799 then 'Very Good'
        When CreditScore between 670 and 739 then 'Good'
        When CreditScore between 580 and 669 then 'Fair'
        When CreditScore between 300 and 579 then 'Poor'
	End as CreditScoreSegment,
    Count(*) as TotalCustomers,
    Sum(Case When Exited = 1 Then 1 Else 0 End) as ExitedCustomers,
    Round((Sum(Case When Exited = 1 Then 1 Else 0 End) * 1.0 / Count(*)) * 100, 2) as ExitRate
From bank_churn
Group by CreditScoreSegment
Order by ExitRate Desc;

-- Q8. Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
Select 
	g.GeographyLocation,
    count(b.IsActiveMember) as NoOfActiveCustomers
From geography g
inner join customerinfo c on c.GeographyID = g.GeographyID
inner join bank_churn b on b.CustomerID = c.CustomerID
Where b.IsActiveMember = 1 and b.Tenure > 5
Group By g.GeographyLocation;

-- Q9. What is the impact of having a credit card on customer churn, based on the available data?
Select 
	Case
		When HasCrCard = 1 Then 'Credit Card Holder'
        Else 'No Credit Card'
	End as CreditCardStatus,
    Count(*) as TotalCustomers,
    Sum(Case when Exited = 1 Then 1 Else 0 End) as ExitedCustomers,
    Round((sum(Case when Exited = 1 Then 1 Else 0 End) * 1.0 / Count(*)) * 100 , 2) as ChurnRate
From bank_churn
Group by CreditCardStatus;

-- Q10. For customers who have exited, what is the most common number of products they have used?
Select 
	NumOfProducts,
    Count(CustomerID) as TotalCustomers
From bank_churn
Where Exited = 1
Group by NumOfProducts
Order by TotalCustomers desc;

-- Q11. Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
SELECT
	YEAR(BankDOJ) AS Year, 
	COUNT(*) AS NewCustomers
FROM customerinfo
GROUP BY YEAR(BankDOJ)
ORDER BY Year;

-- Q12. Analyze the relationship between the number of products and the account balance for customers who have exited.
Select 
	NumOfProducts,
	Count(CustomerID) as TotalCustomer,
    Round(Sum(Balance),2) as TotalBalance
From bank_churn
Where Exited = 1
Group by NumOfProducts
Order by TotalBalance desc;

-- Q15. Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
With cte1 as (
	Select 
		geo.GeographyLocation,
		g.GenderCategory,
		Round(Avg(c.EstimatedSalary),2) as AverageIncome
	from customerinfo c 
	inner join Gender g on c.GenderID = g.GenderID
	inner join Geography geo on c.GeographyID  = geo.GeographyID
	Group by geo.GeographyLocation, g.GenderCategory
)
Select 
	GeographyLocation,
    GenderCategory,
    AverageIncome,
    dense_rank() over (Partition by GenderCategory order by AverageIncome desc) as GenderRank
From cte1
Order by AverageIncome desc;

-- Q16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).
Select 
	Case 
		When c.Age between 18 and 30 Then '18-30'
        When c.AGe between 31 and 50 Then '30-50'
        When c.Age > 50 Then '50+'
	End as AgeBracket,
    Round(Avg(b.Tenure),2) as AvgTenure
From customerinfo c 
Inner join bank_churn b on c.CustomerID = b.CustomerID
Where Exited = 1
Group by AgeBracket
Order by AgeBracket;

-- Q17. Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not?
Select 
	c.CustomerID,
    c.Surname as CustomerName,
    c.EstimatedSalary as CustomerSalary,
    b.Balance as CustomerAccountBalance,
    e.ExitCategory
From customerinfo c 
inner join bank_churn b on b.CustomerID = c.CustomerID
inner join exitcustomer e on e.ExitID = b.Exited
Where b.Exited = 1
Order by CustomerAccountBalance desc;

-- Q18. Is there any correlation between the salary and the Credit score of customers?
Select 
	c.CustomerID,
    c.Surname as CustomerName,
    c.EstimatedSalary as CustomerSalary,
    b.CreditScore,
    b.HasCrCard
From customerinfo c 
inner join bank_churn b on b.CustomerID = c.CustomerID;

-- Q19. Rank each bucket of credit score as per the number of customers who have churned the bank.
With CreditScoreBuckets as (
	Select 
		Case
			When b.CreditScore between 800 and 850 then 'Excellent'
			When b.CreditScore between 740 and 799 then 'Very Good'
			When b.CreditScore between 670 and 739 then 'Good'
			When b.CreditScore between 580 and 669 then 'Fair'
			When b.CreditScore between 300 and 579 then 'Poor'
		End as CreditScoreBucket,
		Count(b.CustomerID) as ChurnedCustomers
	From bank_churn b 
	Where b.Exited = 0
	Group By CreditScoreBucket
)
Select 
	CreditScoreBucket,
    ChurnedCustomers,
    Dense_Rank() Over (Order by ChurnedCustomers Desc) as ChurnRank
From CreditScoreBuckets
Order By ChurnedCustomers desc;

-- Q20. According to the age buckets find the number of customers who have a credit card. Also retrieve those buckets that have lesser than average number of credit cards per bucket.
-- (i) Number of customers who have a credit card per each Age Bucket --
Select 
        Case 
            When c.Age Between 18 And 30 Then '18-30'
            When c.Age Between 31 And 50 Then '31-50'
            Else '50+'
        End As AgeBucket,
        Count(cc.CreditID) AS CreditCardCustomers
From customerinfo c
Left Join bank_churn b ON c.CustomerID = b.CustomerID
Left Join creditcard cc ON b.HasCrCard = cc.CreditID   
Left Join activecustomer a ON b.IsActiveMember = a.ActiveID
Left Join exitcustomer e ON b.Exited = e.ExitID
Left Join gender g ON c.GenderID = g.GenderID
Left Join geography geo ON c.GeographyID = geo.GeographyID
Where cc.CreditID = 1
Group By AgeBucket
Order By AgeBucket;

-- (ii) Age buckets that have lesser than average number of credit cards per bucket.
With AgeBuckets As (
	Select 
		Case 
			When c.Age Between 18 And 30 Then '18-30'
			When c.Age Between 31 And 50 Then '31-50'
			Else '50+' End As AgeBucket, Count(cc.CreditID) AS CreditCardCustomers
	From customerinfo c
	Left Join bank_churn b ON c.CustomerID = b.CustomerID
	Left Join creditcard cc ON b.HasCrCard = cc.CreditID   
	Left Join activecustomer a ON b.IsActiveMember = a.ActiveID
	Left Join exitcustomer e ON b.Exited = e.ExitID
	Left Join gender g ON c.GenderID = g.GenderID
	Left Join geography geo ON c.GeographyID = geo.GeographyID
	Where cc.CreditID = 1
	Group By AgeBucket
	Order By AgeBucket ),
AvgCreditCards As (
    Select Avg(CreditCardCustomers) As AvgCreditCardsPerBucket
    From AgeBuckets
)
Select ab.AgeBucket, ab.CreditCardCustomers
From AgeBuckets ab
Cross Join AvgCreditCards avg_cc
Where ab.CreditCardCustomers < avg_cc.AvgCreditCardsPerBucket
Order By ab.CreditCardCustomers Asc;

-- Q21.  Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
With LocationChurnData As (
	Select 
		geo.GeographyID,
		geo.GeographyLocation,
		Count(b.CustomerID) As ChurnedCustomers,
		Round(Avg(b.Balance),2) As AvgBalance
	From bank_churn b 
	Join customerinfo c on c.CustomerID = b.CustomerID
	Join geography geo on geo.GeographyID = c.GeographyID
	Where Exited = 1
	Group By geo.GeographyID, geo.GeographyLocation
)
Select
	GeographyID,
    GeographyLocation,
    ChurnedCustomers,
    Dense_Rank() Over (Order By ChurnedCustomers) as ChurnRank,
    AvgBalance,
    Dense_Rank() Over (Order by AvgBalance Desc) as BalanceRank
From LocationChurnData
Order By ChurnedCustomers Desc, AvgBalance Desc;

-- Q22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.
Select 
    CustomerID, 
    Surname,
    Concat(CustomerID, '_', Surname) As CustomerID_Surname
From customerinfo;

-- Q23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.
Select 
	b.CustomerID,
    b.CreditScore,
    b.Balance,
    b.Exited,
    (Select e.ExitCategory
	From exitcustomer e 
    Where e.ExitID = b.Exited) as ExitCategory
From bank_churn b
Order By b.Balance desc;

-- Q24. Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them?
-- (i) Checking if bank_churn table has null values
SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Missing_CustomerID,
    SUM(CASE WHEN CreditScore IS NULL THEN 1 ELSE 0 END) AS Missing_CreditScore,
    SUM(CASE WHEN Tenure IS NULL THEN 1 ELSE 0 END) AS Missing_Tenure,
    SUM(CASE WHEN Balance IS NULL THEN 1 ELSE 0 END) AS Missing_Balance,
    SUM(CASE WHEN NumOfProducts IS NULL THEN 1 ELSE 0 END) AS Missing_NumOfProducts,
    SUM(CASE WHEN HasCrCard IS NULL THEN 1 ELSE 0 END) AS Missing_CreditID,
    SUM(CASE WHEN IsActiveMember IS NULL THEN 1 ELSE 0 END) AS Missing_ActiveID,
    SUM(CASE WHEN Exited IS NULL THEN 1 ELSE 0 END) AS Missing_ExitID
FROM bank_churn;

-- (ii) Checking if customerinfo table has null values
SELECT 
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Missing_CustomerID,
    SUM(CASE WHEN Surname IS NULL THEN 1 ELSE 0 END) AS Missing_Surname,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Missing_Age,
    SUM(CASE WHEN GenderID IS NULL THEN 1 ELSE 0 END) AS Missing_GenderID,
    SUM(CASE WHEN EstimatedSalary IS NULL THEN 1 ELSE 0 END) AS Missing_EstimatedSalary,
    SUM(CASE WHEN GeographyID IS NULL THEN 1 ELSE 0 END) AS Missing_GeographyID,
    SUM(CASE WHEN BankDOJ IS NULL THEN 1 ELSE 0 END) AS Missing_BankDOJ
FROM customerinfo;

-- Q25. Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.
Select 
	c.CustomerID,
    c.Surname as LastName,
    a.ActiveCategory
From customerinfo c
inner join bank_churn b on c.CustomerID = b.CustomerID
inner join activecustomer a on a.ActiveID = b.IsActiveMember
Where c.Surname like '%on'
Order By c.Surname;

-- Q26. Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns. One more point to consider is that the data in the Exited Column is absolutely correct and accurate.
select * from bank_churn
where IsActiveMember = 0 and Exited = 0;













