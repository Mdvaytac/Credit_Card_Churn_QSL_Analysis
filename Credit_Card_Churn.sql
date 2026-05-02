--1. Find the average credit limit and average utilization ratio for each income category. 
--Show only categories where the average credit limit is above 5000.

SELECT 
    Income_Category,
    ROUND(AVG(Credit_Limit), 2) AS avg_credit_limit,
    ROUND(AVG(Avg_Utilization_Ratio), 4) AS avg_utilization
FROM credit_card_churn
GROUP BY Income_Category
HAVING AVG(Credit_Limit) > 5000
ORDER BY avg_credit_limit DESC;

--2. Group customers by the number of inactive months in the last 12 months. 
--Count how many customers churned (Attrited Customer) and how many remained (Existing Customer) in each group.

SELECT 
    Months_Inactive_12_mon,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    COUNT(CASE WHEN Attrition_Flag = 'Existing Customer' THEN 1 END) AS retained,
    COUNT(*) AS total
FROM credit_card_churn
GROUP BY Months_Inactive_12_mon
ORDER BY Months_Inactive_12_mon;

--3. Find the gender distribution for each card category. Show the number of customers in each cell.

SELECT 
    Card_Category,
    COUNT(CASE WHEN Gender = 'M' THEN 1 END) AS male_count,
    COUNT(CASE WHEN Gender = 'F' THEN 1 END) AS female_count,
    COUNT(*) AS total
FROM credit_card_churn
GROUP BY Card_Category
ORDER BY total DESC;

--4. Divide customer ages into 5 groups (18-30, 31-40, 41-50, 51-60, 60+). Calculate churn rate (%) in each age group.

SELECT 
    CASE 
        WHEN Customer_Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Customer_Age BETWEEN 31 AND 40 THEN '31-40'
        WHEN Customer_Age BETWEEN 41 AND 50 THEN '41-50'
        WHEN Customer_Age BETWEEN 51 AND 60 THEN '51-60'
        ELSE '60+'
    END AS age_group,
    COUNT(*) AS total,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(
        100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2
    ) AS churn_rate_pct
FROM credit_card_churn
GROUP BY age_group
ORDER BY age_group;

--5. For each education level, find the average monthly contact count (Contacts_Count_12_mon / 12) and show results in descending order.

SELECT 
    Education_Level,
    COUNT(*) AS customer_count,
    ROUND(AVG(Contacts_Count_12_mon / 12.0), 4) AS avg_monthly_contacts
FROM credit_card_churn
GROUP BY Education_Level
ORDER BY avg_monthly_contacts DESC;

--6. Find the top 10 customers with the highest Total_Trans_Amt. Also show their Attrition_Flag, Card_Category and Income_Category.

SELECT 
    CLIENTNUM,
    Attrition_Flag,
    Card_Category,
    Income_Category,
    Total_Trans_Amt,
    Total_Trans_Ct
FROM credit_card_churn
ORDER BY Total_Trans_Amt DESC
LIMIT 10;

--7. Group by number of dependents (Dependent_count). Show average credit limit and average revolving balance difference for each group.

SELECT 
    Dependent_count,
    COUNT(*) AS customer_count,
    ROUND(AVG(Credit_Limit), 2) AS avg_credit_limit,
    ROUND(AVG(Total_Revolving_Bal), 2) AS avg_revolving_bal,
    ROUND(AVG(Credit_Limit) - AVG(Total_Revolving_Bal), 2) AS avg_available_credit
FROM credit_card_churn
GROUP BY Dependent_count
ORDER BY Dependent_count;

--8. For churned customers, show average Total_Trans_Ct and Total_Trans_Amt by marital status, compared with existing customers.

SELECT 
    Marital_Status,
    Attrition_Flag,
    COUNT(*) AS count,
    ROUND(AVG(Total_Trans_Ct), 2) AS avg_trans_count,
    ROUND(AVG(Total_Trans_Amt), 2) AS avg_trans_amount
FROM credit_card_churn
GROUP BY Marital_Status, Attrition_Flag
ORDER BY Marital_Status, Attrition_Flag;

--9. Rank customers within each Income_Category by Credit_Limit. Return top 3 customers per category.

WITH ranked AS (
    SELECT 
        CLIENTNUM,
        Income_Category,
        Credit_Limit,
        Attrition_Flag,
        RANK() OVER (PARTITION BY Income_Category ORDER BY Credit_Limit DESC) AS rnk
    FROM credit_card_churn
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY Income_Category, rnk;

--10. For each Card_Category, calculate how much the average Total_Trans_Amt differs from the overall average (difference and percentage).

SELECT 
    Card_Category,
    COUNT(*) AS count,
    ROUND(AVG(Total_Trans_Amt), 2) AS avg_trans_amt,
    ROUND((SELECT AVG(Total_Trans_Amt) FROM credit_card_churn), 2) AS overall_avg,
    ROUND(AVG(Total_Trans_Amt) - (SELECT AVG(Total_Trans_Amt) FROM credit_card_churn), 2) AS diff,
    ROUND(
        100.0 * (AVG(Total_Trans_Amt) - (SELECT AVG(Total_Trans_Amt) FROM credit_card_churn))
        / (SELECT AVG(Total_Trans_Amt) FROM credit_card_churn), 2
    ) AS pct_diff
FROM credit_card_churn
GROUP BY Card_Category
ORDER BY avg_trans_amt DESC;

--11. Find existing customers whose utilization ratio is higher than the average utilization ratio of churned customers.
--Show their count by card category.

SELECT 
    Card_Category,
    COUNT(*) AS at_risk_customers,
    ROUND(AVG(Avg_Utilization_Ratio), 4) AS avg_utilization
FROM credit_card_churn
WHERE Attrition_Flag = 'Existing Customer'
  AND Avg_Utilization_Ratio > (
      SELECT AVG(Avg_Utilization_Ratio)
      FROM credit_card_churn
      WHERE Attrition_Flag = 'Attrited Customer'
  )
GROUP BY Card_Category
ORDER BY at_risk_customers DESC;

--12. Divide customers into percentiles (25%, 50%, 75%) based on contact count. Calculate churn rate in each percentile group.

WITH quartiles AS (
    SELECT 
        CLIENTNUM,
        Attrition_Flag,
        Contacts_Count_12_mon,
        NTILE(4) OVER (ORDER BY Contacts_Count_12_mon) AS contact_quartile
    FROM credit_card_churn
)
SELECT 
    contact_quartile,
    MIN(Contacts_Count_12_mon) AS min_contacts,
    MAX(Contacts_Count_12_mon) AS max_contacts,
    COUNT(*) AS total,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(
        100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2
    ) AS churn_rate_pct
FROM quartiles
GROUP BY contact_quartile
ORDER BY contact_quartile;

--13. Compare each customer's Total_Trans_Amt with their Income_Category average and label as "above_avg" or "below_avg". 
--Calculate churn rate based on these labels.

WITH labeled AS (
    SELECT 
        CLIENTNUM,
        Attrition_Flag,
        Income_Category,
        Total_Trans_Amt,
        AVG(Total_Trans_Amt) OVER (PARTITION BY Income_Category) AS income_avg,
        CASE 
            WHEN Total_Trans_Amt >= AVG(Total_Trans_Amt) OVER (PARTITION BY Income_Category) 
            THEN 'above_avg'
            ELSE 'below_avg'
        END AS trans_label
    FROM credit_card_churn
)
SELECT 
    trans_label,
    COUNT(*) AS total,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(
        100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2
    ) AS churn_rate_pct
FROM labeled
GROUP BY trans_label;

--14. Identify high churn risk customers: Months_Inactive_12_mon >= 3 AND Contacts_Count_12_mon >= 4 
--AND Avg_Utilization_Ratio < 0.1. Compare this segment's churn rate with overall churn rate.

WITH high_risk AS (
    SELECT *
    FROM credit_card_churn
    WHERE Months_Inactive_12_mon >= 3
      AND Contacts_Count_12_mon >= 4
      AND Avg_Utilization_Ratio < 0.1
)
SELECT 
    'High Risk Segment' AS segment,
    COUNT(*) AS total,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(
        100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2
    ) AS churn_rate_pct,
    ROUND(
        (SELECT 100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*)
         FROM credit_card_churn), 2
    ) AS overall_churn_rate_pct
FROM high_risk;

--15. Calculate each customer's Total_Revolving_Bal as a percentage of the cumulative total within their Card_Category.
--Show only customers contributing more than 80% of their group.

WITH cumulative AS (
    SELECT 
        CLIENTNUM,
        Card_Category,
        Total_Revolving_Bal,
        SUM(Total_Revolving_Bal) OVER (PARTITION BY Card_Category) AS group_total,
        ROUND(
            100.0 * Total_Revolving_Bal / 
            NULLIF(SUM(Total_Revolving_Bal) OVER (PARTITION BY Card_Category), 0), 4
        ) AS pct_of_group
    FROM credit_card_churn
)
SELECT 
    CLIENTNUM,
    Card_Category,
    Total_Revolving_Bal,
    group_total,
    pct_of_group
FROM cumulative
WHERE pct_of_group > 80
ORDER BY Card_Category, pct_of_group DESC;

--16. Compute running total of Total_Trans_Amt for each Income_Category and Card_Category combination.
--Return the first customer where cumulative total exceeds 50% of group total.

WITH running AS (
    SELECT
        CLIENTNUM,
        Income_Category,
        Card_Category,
        Total_Trans_Amt,
        SUM(Total_Trans_Amt) OVER (
            PARTITION BY Income_Category, Card_Category
            ORDER BY Total_Trans_Amt DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total,
        SUM(Total_Trans_Amt) OVER (
            PARTITION BY Income_Category, Card_Category
        ) AS group_total
    FROM credit_card_churn
),
flagged AS (
    SELECT *,
        running_total * 1.0 / NULLIF(group_total, 0) AS cum_pct,
        LAG(running_total * 1.0 / NULLIF(group_total, 0)) OVER (
            PARTITION BY Income_Category, Card_Category
            ORDER BY Total_Trans_Amt DESC
        ) AS prev_pct
    FROM running
)
SELECT
    Income_Category,
    Card_Category,
    CLIENTNUM,
    Total_Trans_Amt,
    ROUND(cum_pct * 100, 2) AS cumulative_pct
FROM flagged
WHERE (prev_pct IS NULL OR prev_pct < 0.5)
  AND cum_pct >= 0.5
ORDER BY Income_Category, Card_Category;

--ADVANCED TASKS

--Build a simple scoring model to estimate churn probability:
-- +2 if inactive months are high, +3 if contacts >= 4, +2 if utilization < 0.1, +1 if Total_Trans_Ct is low.
--Calculate proportion of high-risk customers (score >= 5) by Education_Level.

WITH scored AS (
    SELECT
        CLIENTNUM,
        Education_Level,
        Attrition_Flag,
        (
            CASE WHEN Months_Inactive_12_mon >= 3 THEN 2 ELSE 0 END +
            CASE WHEN Contacts_Count_12_mon >= 4 THEN 3 ELSE 0 END +
            CASE WHEN Avg_Utilization_Ratio < 0.1 THEN 2 ELSE 0 END +
            CASE WHEN Total_Trans_Ct < 40 THEN 1 ELSE 0 END
        ) AS risk_score
    FROM credit_card_churn
)
SELECT
    Education_Level,
    COUNT(*) AS total,
    COUNT(CASE WHEN risk_score >= 5 THEN 1 END) AS high_risk_count,
    ROUND(100.0 * COUNT(CASE WHEN risk_score >= 5 THEN 1 END) / COUNT(*), 2) AS high_risk_pct,
    ROUND(100.0 * COUNT(CASE WHEN risk_score >= 5 AND Attrition_Flag = 'Attrited Customer' THEN 1 END)
          / NULLIF(COUNT(CASE WHEN risk_score >= 5 THEN 1 END), 0), 2) AS actual_churn_among_high_risk
FROM scored
GROUP BY Education_Level
ORDER BY high_risk_pct DESC;

--Segment customers within each Income_Category based on their position by Total_Trans_Amt as "top 10%", "middle 80%", "bottom 10%".
--Compare churn rates across these segments. (Use PERCENTILE_CONT or NTILE)

WITH deciled AS (
    SELECT
        CLIENTNUM,
        Income_Category,
        Attrition_Flag,
        Total_Trans_Amt,
        NTILE(10) OVER (
            PARTITION BY Income_Category
            ORDER BY Total_Trans_Amt
        ) AS decile
    FROM credit_card_churn
),
labeled AS (
    SELECT *,
        CASE
            WHEN decile = 10 THEN 'top 10%'
            WHEN decile = 1  THEN 'bottom 10%'
            ELSE 'middle 80%'
        END AS segment
    FROM deciled
)
SELECT
    Income_Category,
    segment,
    COUNT(*) AS total,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2) AS churn_pct
FROM labeled
GROUP BY Income_Category, segment
ORDER BY Income_Category,
    CASE segment WHEN 'top 10%' THEN 1 WHEN 'middle 80%' THEN 2 ELSE 3 END;

--For each Marital_Status × Gender combination, divide customers into cohorts based on Months_on_book (0-12, 13-24, 25-36, 36+).
--Calculate churn rate for each cohort × combination. Return top 5 combinations with highest churn.

WITH cohorts AS (
    SELECT
        Marital_Status,
        Gender,
        Attrition_Flag,
        CASE
            WHEN Months_on_book BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN Months_on_book BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN Months_on_book BETWEEN 25 AND 36 THEN '25-36 months'
            ELSE '36+ months'
        END AS cohort
    FROM credit_card_churn
)
SELECT
    Marital_Status,
    Gender,
    cohort,
    COUNT(*) AS total,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2) AS churn_pct
FROM cohorts
GROUP BY Marital_Status, Gender, cohort
HAVING COUNT(*) >= 10
ORDER BY churn_pct DESC
LIMIT 5;

--Without using a recursive CTE, generate all possible Income_Category pairs (A → B) using CROSS JOIN.
--For each pair, calculate average Credit_Limit difference and total customer count difference.
--Show only pairs where absolute difference is greater than 2000.

WITH income_stats AS (
    SELECT
        Income_Category,
        ROUND(AVG(Credit_Limit), 2) AS avg_limit,
        COUNT(*) AS customer_count
    FROM credit_card_churn
    GROUP BY Income_Category
)
SELECT
    a.Income_Category AS category_a,
    b.Income_Category AS category_b,
    a.avg_limit AS avg_limit_a,
    b.avg_limit AS avg_limit_b,
    ROUND(ABS(a.avg_limit - b.avg_limit), 2) AS limit_diff,
    ABS(a.customer_count - b.customer_count) AS count_diff
FROM income_stats a
CROSS JOIN income_stats b
WHERE a.Income_Category < b.Income_Category
  AND ABS(a.avg_limit - b.avg_limit) > 2000
ORDER BY limit_diff DESC;

--Compare distribution of each feature (Gender, Education_Level, Marital_Status, Card_Category) 
--for churned vs existing customers. Find the largest distribution difference (absolute % difference).
--Write this analysis in a single query using UNION ALL.

WITH base AS (
    SELECT Attrition_Flag, Gender, Education_Level, Marital_Status, Card_Category
    FROM credit_card_churn
),
gender_diff AS (
    SELECT 'Gender' AS feature, Gender AS value,
        ROUND(100.0 * SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0), 2) AS attrited_pct,
        ROUND(100.0 * SUM(CASE WHEN Attrition_Flag='Existing Customer' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0), 2) AS existing_pct
    FROM base GROUP BY Gender
),
edu_diff AS (
    SELECT 'Education' AS feature, Education_Level AS value,
        ROUND(100.0 * SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0), 2) AS attrited_pct,
        ROUND(100.0 * SUM(CASE WHEN Attrition_Flag='Existing Customer' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0), 2) AS existing_pct
    FROM base GROUP BY Education_Level
),
card_diff AS (
    SELECT 'Card_Category' AS feature, Card_Category AS value,
        ROUND(100.0 * SUM(CASE WHEN Attrition_Flag='Attrited Customer' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0), 2) AS attrited_pct,
        ROUND(100.0 * SUM(CASE WHEN Attrition_Flag='Existing Customer' THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*),0), 2) AS existing_pct
    FROM base GROUP BY Card_Category
),
all_features AS (
    SELECT * FROM gender_diff
    UNION ALL SELECT * FROM edu_diff
    UNION ALL SELECT * FROM card_diff
)
SELECT
    feature,
    value,
    attrited_pct,
    existing_pct,
    ROUND(ABS(attrited_pct - existing_pct), 2) AS abs_diff
FROM all_features
ORDER BY feature, abs_diff DESC;

--Calculate a "loyalty index" for each customer: 
--(Total_Relationship_Count × 0.3) + (Total_Trans_Ct × 0.4) + ((1 - Avg_Utilization_Ratio) × 100 × 0.3).
--Normalize this index within each Card_Category (min-max scaling: 0-100).
--Find churn rate for the bottom 20% group within each card category based on normalized index.

WITH raw_index AS (
    SELECT
        CLIENTNUM,
        Card_Category,
        Attrition_Flag,
        (Total_Relationship_Count * 0.3)
        + (Total_Trans_Ct * 0.4)
        + ((1 - Avg_Utilization_Ratio) * 100 * 0.3) AS loyalty_raw
    FROM credit_card_churn
),
normalized AS (
    SELECT *,
        ROUND(
            100.0 * (loyalty_raw - MIN(loyalty_raw) OVER (PARTITION BY Card_Category))
            / NULLIF(
                MAX(loyalty_raw) OVER (PARTITION BY Card_Category)
                - MIN(loyalty_raw) OVER (PARTITION BY Card_Category), 0
            ), 2
        ) AS loyalty_norm,
        NTILE(5) OVER (PARTITION BY Card_Category ORDER BY loyalty_raw) AS quintile
    FROM raw_index
)
SELECT
    Card_Category,
    COUNT(*) AS total_bottom_20pct,
    COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) AS churned,
    ROUND(100.0 * COUNT(CASE WHEN Attrition_Flag = 'Attrited Customer' THEN 1 END) / COUNT(*), 2) AS churn_pct,
    ROUND(AVG(loyalty_norm), 2) AS avg_loyalty_norm
FROM normalized
WHERE quintile = 1
GROUP BY Card_Category
ORDER BY churn_pct DESC;

