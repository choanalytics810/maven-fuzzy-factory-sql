-- Analyzing Top Websitwe Pages & Entry Pages

-- Finding Top Website Pages
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS sessions
FROM website_pageviews

WHERE created_at < '2012-06-09'
GROUP BY 1
ORDER BY sessions DESC;
/* The most view website is the home page which as a 10,403 sessions before 06/09/2012. */


-- Finding Top Entry Pages
CREATE TEMPORARY TABLE first_pv_per_session
SELECT
	website_session_id,
    MIN(website_pageview_id) as first_pv   -- 每一次的user造訪網站時(website_session_id)，用MIN(website_pageview_id)找到第一個pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id ;   

SELECT * FROM first_pv_per_session;

SELECT 
	website_pageviews.pageview_url AS landing_page,
    COUNT(DISTINCT first_pv_per_session.website_session_id) AS sessions_hitting_this_landing_page
FROM first_pv_per_session

LEFT JOIN website_pageviews
	ON first_pv_per_session.first_pv = website_pageviews.website_pageview_id  -- 連接的key要注意
WHERE created_at < '2012-06-12'
GROUP BY 1;


-- Calculating Bounce Rates

-- Step 1: finding the first website_pageview_id for relevant sessions
-- CREATE TEMPORARY TABLE first_pageviews
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY 1;
SELECT * FROM first_pageviews;


-- Step 2: identifying the landing page of each session
CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT 
	first_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_pageviews

LEFT JOIN website_pageviews
	ON first_pageviews.min_pageview_id = website_pageviews.website_pageview_id;
SELECT * FROM sessions_w_landing_page;
-- Step 3: counting pageviews for each session, to identify "bounces"
CREATE TEMPORARY TABLE bounced_sessions
SELECT 
	sessions_w_landing_page.website_session_id,
    sessions_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_view
FROM sessions_w_landing_page

LEFT JOIN website_pageviews
	ON sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY 1,2
HAVING COUNT(website_pageviews.website_pageview_id) = 1;


SELECT * FROM bounced_sessions;
-- Step 4: summarizing by counting total sessions and bounced sessions
SELECT 
	sessions_w_landing_page.landing_page,
    COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_sessions,
    COUNT(DISTINCT bounced_sessions.website_session_id) / COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS bounce_rate
FROM sessions_w_landing_page

LEFT JOIN bounced_sessions
	ON bounced_sessions.website_session_id = sessions_w_landing_page.website_session_id
GROUP BY 1;


-- Analyzing Landing Page Tests

-- Step 0: find out when the new page / lander launched
SELECT
	WEEK(created_at),
    MIN(DATE(created_at)),
    COUNT(DISTINCT website_pageview_id),
    pageview_url,
    website_pageview_id
FROM website_pageviews
WHERE created_at < '2012-07-28'
	AND pageview_url = '/lander-1'
GROUP BY 1,4,5;   
-- New custom landing page '/lander-1' started launching from Week 25, 06-19-2012, and the website_pv_id is 23504


-- finding the first website_pageview_id for relevant sessions
CREATE TEMPORARY TABLE first_test_pageviews
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at < '2012-07-28' AND website_pageviews.website_pageview_id > 23504
	AND pageview_url IN ('/lander-1','/home')
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 1;

SELECT * FROM first_test_pageviews;
-- Step 2: identifying the landing page of each session
CREATE TEMPORARY TABLE lander1_test_sessions_w_landing_page
SELECT 
	first_test_pageviews.website_session_id,
    website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews 
	ON first_test_pageviews.min_pv_id = website_pageviews.website_pageview_id
WHERE website_pageviews.pageview_url IN ('/lander-1','/home');

SELECT * FROM lander1_test_sessions_w_landing_page;


-- Step 3: counting pageviews for each session, to identify "bounces"
CREATE TEMPORARY TABLE lander1_test_bounce_sessions
SELECT
	lander1_test_sessions_w_landing_page.website_session_id,
    lander1_test_sessions_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS count_of_pages_views
FROM lander1_test_sessions_w_landing_page
LEFT JOIN website_pageviews
	ON lander1_test_sessions_w_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY 1,2
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

SELECT * FROM lander1_test_bounce_sessions;

-- Step 4: summarizing total sessions and bounced sessions, by LP
SELECT
	lander1_test_sessions_w_landing_page.landing_page,
	COUNT(lander1_test_sessions_w_landing_page.website_session_id) AS sessions,
    COUNT(lander1_test_bounce_sessions.count_of_pages_views) AS bounced_sessions,
    COUNT(lander1_test_bounce_sessions.count_of_pages_views) / COUNT(lander1_test_sessions_w_landing_page.website_session_id) AS bounced_rate
FROM lander1_test_sessions_w_landing_page
LEFT JOIN lander1_test_bounce_sessions
	ON lander1_test_sessions_w_landing_page.website_session_id = lander1_test_bounce_sessions.website_session_id
GROUP BY 1;
-- The new custom landing page "lander1" does successfully lower the bounce rate by around 5 percent


-- Landing Page Trend Analysis

-- Step 1: finding the first website_pageview_id for relevant sessions
CREATE TEMPORARY TABLE sessions_w_min_id_and_pv_count
SELECT
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS first_pageview_id,
    COUNT(website_pageviews.pageview_url) AS count_pageviews
FROM website_sessions
	INNER JOIN website_pageviews
		ON website_pageviews.website_session_id = website_sessions.website_session_id

WHERE website_pageviews.created_at > "2012-06-01" AND website_pageviews.created_at < "2012-08-31"
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY 1;

SELECT * FROM sessions_w_min_id_and_pv_count;
-- Step 2: identifying the landing page of each session
CREATE TEMPORARY TABLE sessions_w_pv_counts_lp_created_at
SELECT 
	sessions_w_min_id_and_pv_count.website_session_id,
    sessions_w_min_id_and_pv_count.first_pageview_id,
    sessions_w_min_id_and_pv_count.count_pageviews,
    website_pageviews.pageview_url,
    website_pageviews.created_at
FROM sessions_w_min_id_and_pv_count
	LEFT JOIN website_pageviews
		ON sessions_w_min_id_and_pv_count.website_session_id = website_pageviews.website_session_id
WHERE pageview_url IN ('/lander-1', '/home');

SELECT * FROM sessions_w_pv_counts_lp_created_at;
-- Step 3: counting pageviews for each session, to identify "bounces"
CREATE TEMPORARY TABLE lp_test_bounced_sessions
SELECT 
	sessions_w_pv_counts_lp_created_at.website_session_id,
    sessions_w_pv_counts_lp_created_at.pageview_url,
    COUNT(website_pageviews.website_session_id) AS count_of_page_views
FROM sessions_w_pv_counts_lp_created_at
	LEFT JOIN website_pageviews
		ON sessions_w_pv_counts_lp_created_at.website_session_id = website_pageviews.website_session_id
GROUP BY 1,2
HAVING COUNT(website_pageviews.website_session_id) = 1;

SELECT * FROM lp_test_bounced_sessions;
-- Step 4: summarizing by week (bounce rate, sessions to each lander)
SELECT
	MIN(DATE(created_at)) AS week_start_date,
    -- COUNT(DISTINCT website_session_id) AS total_sessions,
    -- COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
	COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN pageview_url = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(DISTINCT CASE WHEN pageview_url = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM sessions_w_pv_counts_lp_created_at
GROUP BY YEARWEEK(created_at);
/* After couple months the traffic has been fully switched to the new custom landing page and also has a lower
	bounce rate(lower by 5-10%) compared to the original home page */


-- Buildling Conversion Funnels (2012-08-05~2012-09-05) 

-- Identify all pageviews between the period
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageviews.website_session_id)
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at > '2012-08-05' AND website_pageviews.created_at < '2012-09-05'
GROUP BY 1
ORDER BY COUNT(DISTINCT website_pageviews.website_session_id) DESC;  

-- Select all pageviews for relevant sessions
SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at,
    CASE WHEN pageview_url = '/products' THEN 1 else 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 else 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 else 0 END AS cart_page,
    CASE WHEN pageview_url = '/home' THEN 1 else 0 END AS home_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 else 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 else 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 else 0 END AS thankyou_page
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at > '2012-08-05' AND website_pageviews.created_at < '2012-09-05';

-- create the session-level conversion funnel view
CREATE TEMPORARY TABLE session_level_made_it
SELECT
	website_session_id,
    MAX(products_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(home_page) AS home_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM(
	
    SELECT
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    website_pageviews.created_at,
    CASE WHEN pageview_url = '/products' THEN 1 else 0 END AS products_page,
    CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 else 0 END AS mrfuzzy_page,
    CASE WHEN pageview_url = '/cart' THEN 1 else 0 END AS cart_page,
    CASE WHEN pageview_url = '/home' THEN 1 else 0 END AS home_page,
    CASE WHEN pageview_url = '/shipping' THEN 1 else 0 END AS shipping_page,
    CASE WHEN pageview_url = '/billing' THEN 1 else 0 END AS billing_page,
    CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 else 0 END AS thankyou_page
FROM website_pageviews
	LEFT JOIN website_sessions
		ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at > '2012-08-05' AND website_pageviews.created_at < '2012-09-05'
	AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
	) AS pageview_level
GROUP BY 1;

SELECT * FROM session_level_made_it;

-- aggregate the data to assess funnel performance
SELECT
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level_made_it;

-- calculate convsersion rate
SELECT
	COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT website_session_id) AS lander_click_rate,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS products_click_rate,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_click_rate,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rate,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rate,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) / COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS thankyou_click_rate
FROM session_level_made_it;



