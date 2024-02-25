/*Requirements
Reshape the data so we have 5 rows for each customer, with responses for the Mobile App and Online Interface being in separate fields on the same row
Clean the question categories so they don't have the platform in from of them
e.g. Mobile App - Ease of Use should be simply Ease of Use
Exclude the Overall Ratings, these were incorrectly calculated by the system
Calculate the Average Ratings for each platform for each customer 
Calculate the difference in Average Rating between Mobile App and Online Interface for each customer
Catergorise customers as being:
Mobile App Superfans if the difference is greater than or equal to 2 in the Mobile App's favour
Mobile App Fans if difference >= 1
Online Interface Fan
Online Interface Superfan
Neutral if difference is between 0 and 1
Calculate the Percent of Total customers in each category, rounded to 1 decimal place*/


--first (un) pivot the the columns into rows
SELECT *
    FROM 
(SELECT *
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK06_DSB_CUSTOMER_SURVEY) AS src--first source table
    UNPIVOT(scale FOR mobile_ratings IN (MOBILE_APP___EASE_OF_USE, MOBILE_APP___EASE_OF_ACCESS, MOBILE_APP___NAVIGATION, MOBILE_APP___LIKELIHOOD_TO_RECOMMEND, MOBILE_APP___OVERALL_RATING,
                                  ONLINE_INTERFACE___EASE_OF_USE, ONLINE_INTERFACE___EASE_OF_ACCESS, ONLINE_INTERFACE___NAVIGATION, ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND,
	                              ONLINE_INTERFACE___OVERALL_RATING
)) AS pvt -- first pivot

--create a split_part to segment my platform and method

SELECT customer_id
      ,split_part(mobile_ratings, '___', 1) AS platform
      ,split_part(mobile_ratings, '___', 2) AS method
      ,scale
    FROM 
(SELECT *
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK06_DSB_CUSTOMER_SURVEY) AS src--first source table
    UNPIVOT(scale FOR mobile_ratings IN (MOBILE_APP___EASE_OF_USE, MOBILE_APP___EASE_OF_ACCESS, MOBILE_APP___NAVIGATION, MOBILE_APP___LIKELIHOOD_TO_RECOMMEND, MOBILE_APP___OVERALL_RATING,
                                  ONLINE_INTERFACE___EASE_OF_USE, ONLINE_INTERFACE___EASE_OF_ACCESS, ONLINE_INTERFACE___NAVIGATION, ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND,
	                              ONLINE_INTERFACE___OVERALL_RATING
)) AS pvt -- first pivot


--online and mobile device are  both on one column so I need to re pivot to get them on differnt fields


WITH cte AS
(
SELECT customer_id
      ,split_part(mobile_ratings, '___', 1) AS platform
      ,split_part(mobile_ratings, '___', 2) AS method
      ,scale
    FROM 
(SELECT *
    FROM TIL_PLAYGROUND.PREPPIN_DATA_INPUTS.PD2023_WK06_DSB_CUSTOMER_SURVEY) AS src--first source table
    UNPIVOT(scale FOR mobile_ratings IN (MOBILE_APP___EASE_OF_USE, MOBILE_APP___EASE_OF_ACCESS, MOBILE_APP___NAVIGATION, MOBILE_APP___LIKELIHOOD_TO_RECOMMEND, MOBILE_APP___OVERALL_RATING,
                                  ONLINE_INTERFACE___EASE_OF_USE, ONLINE_INTERFACE___EASE_OF_ACCESS, ONLINE_INTERFACE___NAVIGATION, ONLINE_INTERFACE___LIKELIHOOD_TO_RECOMMEND,
	                              ONLINE_INTERFACE___OVERALL_RATING
)) AS pvt -- first pivot
)
,cte1 AS     --CTE1 was brought in to be used a s areference for aggreegate calculations
(
SELECT *
    FROM cte
    pivot(min(scale)FOR platform IN ('MOBILE_APP', 'ONLINE_INTERFACE'))--second pivot
    WHERE method!='OVERALL_RATING'
)
, cte2 AS
(
SELECT customer_id
      ,avg("'MOBILE_APP'") AS mobile_avg
      ,avg("'ONLINE_INTERFACE'") AS online_avg
      ,mobile_avg-online_avg AS rating_variance,
      CASE
      WHEN rating_variance >=2 THEN 'mobile_app_superfans'
      WHEN rating_variance >=1 THEN 'mobile_app_fans'
      WHEN rating_variance <=-2 THEN 'online_superfans'
      WHEN rating_variance <=-1 THEN 'online_fans'
      ELSE 'neutral' END AS fan_category
    FROM cte1
    --WHERE customer_id=535084
    GROUP BY 1
    )
    SELECT fan_category
          ,count(customer_id) AS customer_per_category
          ,(SELECT count(DISTINCT customer_id) FROM cte2) AS total_customers
          ,round(customer_per_category/total_customers*100,1) AS customer_percentage
          FROM cte2
          GROUP BY 1;
