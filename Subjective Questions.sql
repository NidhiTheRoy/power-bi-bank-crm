-- Q1. Customer Behavior Analysis: What patterns can be observed in the spending habits of long-term customers compared to new customers, and what might these patterns suggest about customer loyalty?
SELECT 
    CASE 
        WHEN b.Tenure > 3 THEN 'Long-Term'
        ELSE 'New'
    END AS CustomerType,
    Round(AVG(b.Balance),2) AS AvgBalance,
    COUNT(b.CustomerID) AS NumberOfCustomers,
    Round(AVG(b.NumOfProducts),2) AS AvgProducts,
    Round(AVG(b.CreditScore),2) AS AvgCreditScore
FROM bank_churn b
GROUP BY CustomerType
ORDER BY CustomerType DESC;

-- Q2. Product Affinity Study: Which bank products or services are most commonly used together, and how might this influence cross-selling strategies?
WITH ProductUsage AS (
	SELECT 
		CustomerID, 
        NumOfProducts,
		CASE 
			WHEN NumOfProducts = 1 THEN 'SavingsAccount'
			WHEN NumOfProducts = 2 THEN 'SavingsAccount, CreditCard'
			WHEN NumOfProducts = 3 THEN 'SavingsAccount, CreditCard, Loan'
			WHEN NumOfProducts >= 4 THEN 'SavingsAccount, CreditCard, Loan, InvestmentAccount'
		END AS ProductCombination
	FROM bank_churn
),
CombinationAnalysis AS (
	SELECT 
		ProductCombination, 
		COUNT(CustomerID) AS CustomerCount
	FROM ProductUsage
	GROUP BY ProductCombination
)
SELECT 
	CustomerCount,
    ProductCombination,
    ROUND(CustomerCount/(SELECT COUNT(*) FROM bank_churn) * 100, 2) AS PercentageOfCustomers
FROM CombinationAnalysis;

-- Q3. Geographic Market Trends: How do economic indicators in different geographic regions correlate with the number of active accounts and customer churn rates?
SELECT 
    geo.GeographyLocation,
    COUNT(b.Exited) AS ChurnedCustomers,
    (COUNT(DISTINCT b.Exited) / COUNT(DISTINCT c.CustomerID)) * 100 AS ChurnRate
FROM geography geo
JOIN customerinfo c ON geo.GeographyID = c.GeographyID
JOIN bank_churn b ON c.CustomerID = b.CustomerID
LEFT JOIN exitcustomer e ON b.Exited = e.ExitID
WHERE b.Exited = 1
GROUP BY geo.GeographyLocation;

-- Q4. Risk Management Assessment: Based on customer profiles, which demographic segments appear to pose the highest financial risk to the bank, and why?
SELECT 
    g.GeographyLocation, c.Surname, c.Age, c.EstimatedSalary, bc.CreditScore, bc.Tenure, 
    bc.Balance, bc.NumOfProducts, 
    COUNT(DISTINCT ac.ActiveID) AS ActiveAccounts, 
    COUNT(DISTINCT bc.Exited) AS ChurnedCustomers,
    CASE 
        WHEN bc.CreditScore < 600 THEN 'High Risk: Low Credit Score'
        WHEN bc.Balance > (c.EstimatedSalary * 1.5) THEN 'High Risk: High Balance/Low Salary'
        WHEN bc.Tenure < 1 THEN 'High Risk: Short Tenure'
        WHEN g.GeographyLocation = 'Spain' THEN 'High Risk: High Churn Region'
        ELSE 'Low Risk'
    END AS RiskLevel,
    (COUNT(DISTINCT bc.Exited) / COUNT(DISTINCT c.CustomerID)) * 100 AS ChurnRate
FROM geography g
JOIN customerinfo c ON g.GeographyID = c.GeographyID
JOIN bank_churn bc ON c.CustomerID = bc.CustomerID
LEFT JOIN activecustomer ac ON bc.IsActiveMember = ac.ActiveID
LEFT JOIN exitcustomer ec ON bc.Exited = ec.ExitID
GROUP BY g.GeographyLocation, c.CustomerID, c.Surname, c.Age, c.EstimatedSalary, bc.CreditScore, bc.Tenure, 
    bc.Balance, bc.NumOfProducts
HAVING RiskLevel IN ('High Risk: Low Credit Score', 'High Risk: High Balance/Low Salary', 'High Risk: Short Tenure', 'High Risk: High Churn Region')
ORDER BY g.GeographyLocation, RiskLevel DESC;


-- Q5. Customer Tenure Value Forecast: How would you use the available data to model and predict the lifetime (tenure) value in the bank of different customer segments?
SELECT 
    c.CustomerID,
    c.Age,
    c.EstimatedSalary,
    b.CreditScore,
    b.Tenure,
    b.Balance,
    b.NumOfProducts,
    cc.Category AS CreditCardCategory,
    a.ActiveCategory,
    e.ExitCategory,
    DATEDIFF(CURDATE(), c.BankDOJ) / 365 AS CurrentTenureYears
FROM customerinfo c
JOIN geography geo ON c.GeographyID = geo.GeographyID
JOIN bank_churn b ON c.CustomerID = b.CustomerID
LEFT JOIN creditcard cc ON b.HasCrCard = cc.CreditID
LEFT JOIN activecustomer a ON b.IsActiveMember = a.ActiveID
LEFT JOIN exitcustomer e ON b.Exited = e.ExitID;

-- Q6. Marketing Campaign Effectiveness: How could you assess the impact of marketing campaigns on customer retention and acquisition within the dataset? What extra information would you need to solve this?
-- Answer in word file


-- Q7. Customer Exit Reasons Exploration: Can you identify common characteristics or trends among customers who have exited that could explain their reasons for leaving?
SELECT 
    c.Age, c.EstimatedSalary, b.CreditScore, b.Tenure, b.Balance, b.NumOfProducts, 
    COUNT(b.CustomerID) AS TotalExitedCustomers
FROM customerinfo c
JOIN bank_churn b ON c.CustomerID = b.CustomerID
JOIN geography geo ON c.GeographyID = geo.GeographyID
LEFT JOIN activecustomer a ON b.IsActiveMember = a.ActiveID
LEFT JOIN exitcustomer e ON b.Exited = e.ExitID
WHERE b.Exited = 1  
GROUP BY c.Age, c.EstimatedSalary, b.CreditScore, b.Tenure, b.Balance, b.NumOfProducts
ORDER BY TotalExitedCustomers DESC;

-- Q8. Are 'Tenure', 'NumOfProducts', 'IsActiveMember', and 'EstimatedSalary' important for predicting if a customer will leave the bank?
-- Answer in word file



-- Q9. Utilize SQL queries to segment customers based on demographics and account details.
SELECT 
	c.CustomerID, c.Age, b.CreditScore, b.Balance, b.Tenure, g.GenderCategory, geo.GeographyLocation,
	CASE 
		WHEN c.Age < 25 THEN 'Youth (Under 25)'
		WHEN c.Age BETWEEN 25 AND 35 THEN 'Young Adults (25-35)'
		WHEN c.Age BETWEEN 36 AND 50 THEN 'Middle Age (36-50)'
		ELSE 'Senior (Above 50)'
	END AS AgeGroup,
	CASE 
		WHEN b.CreditScore < 500 THEN 'Poor Credit'
		WHEN b.CreditScore BETWEEN 500 AND 700 THEN 'Average Credit'
		ELSE 'Good Credit'
	END AS CreditScoreCategory,
	CASE 
		WHEN b.Balance < 10000 THEN 'Low Balance'
		WHEN b.Balance BETWEEN 10000 AND 50000 THEN 'Medium Balance'
		ELSE 'High Balance'
	END AS BalanceCategory,
	CASE 
		WHEN b.Tenure < 2 THEN 'New Customer'
		WHEN b.Tenure BETWEEN 2 AND 5 THEN 'Moderate Customer'
		ELSE 'Loyal Customer'
	END AS TenureSegment,
	CASE 
		WHEN HasCrCard = 1 THEN 'Credit Card Holder'
		ELSE 'Non-Credit Card Holder'
	END AS CreditCardSegment
FROM bank_churn b
JOIN customerinfo c on c.CustomerID=b.CustomerID
JOIN gender g on g.GenderID=c.GenderID
JOIN geography geo on geo.GeographyID=c.GeographyID;

-- Q10. How can we create a conditional formatting setup to visually highlight customers at risk of churn and to evaluate the impact of credit card rewards on customer retention?
-- Answer in word file

-- Q11. What is the current churn rate per year and overall as well in the bank? Can you suggest some insights to the bank about which kind of customers are more likely to churn and what different strategies can be used to decrease the churn rate?
SELECT (COUNT( bc.CustomerID) / (SELECT COUNT(DISTINCT CustomerID) FROM customerinfo)) * 100 AS OverallChurnRate
FROM bank_churn bc
WHERE bc.Exited IS NOT NULL;

SELECT 
    YEAR(c.BankDOJ) AS YearJoined, 
    (COUNT(DISTINCT bc.CustomerID) / (SELECT COUNT(DISTINCT CustomerID) FROM customerinfo WHERE YEAR(BankDOJ) = YEAR(c.BankDOJ))) * 100 AS YearlyChurnRate
FROM customerinfo c
JOIN bank_churn bc ON c.CustomerID = bc.CustomerID
WHERE bc.Exited IS NOT NULL
GROUP BY YearJoined
ORDER BY YearJoined;


-- Q12. Create a dashboard incorporating all the KPIs and visualization-related metrics. Use a slicer in order to assist in selection in the dashboard.-- 
-- Answer in word file

-- Q13. How would you approach this problem, if the objective and subjective questions weren't given?
-- Answer in word file


-- Q14. In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?
-- Answer in word file
ALTER TABLE bank_churn
CHANGE HasCrCard Has_creditcard INT;
Select * from bank_churn;

