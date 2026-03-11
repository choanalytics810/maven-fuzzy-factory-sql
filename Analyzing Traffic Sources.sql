
-- Analyzing Traffic Sources

-- Finding Top Traffic Sources
SELECT 
	utm_source,
	utm_campaign,
	http_referer,
	COUNT(website_session_id) AS sessions
FROM website_sessions

WHERE created_at < '2012-04-12'
GROUP BY utm_source, utm_campaign, http_referer;
/* Almost all of the sessions(3613) came from the utm_source gsearch 
and utm_campaign nonbrand while the customer are using mobile device */


-- Traffic Source Conversion Rates
SELECT
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate
FROM website_sessions

LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-04-14'
	AND website_sessions.utm_source = 'gsearch'                      -- gsearch, nonbrand is the major traffic source of the company in this case, and see if we need to reduce bids
    AND website_sessions.utm_campaign = 'nonbrand';					 -- the conv rate before 04/14/2012 is 0.0288
    
-- Traffic Source Trending
SELECT
	WEEK(created_at),
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions

WHERE created_at < '2012-05-10'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand' 
GROUP BY 1;
/* From the total sessions starting from every week, we can see that the marketing director bid down gsearch nonbrand starting from 2012-04-15.
	There is a significant volume drop after that week */

-- Traffic Source Bid Optimization
SELECT
	website_sessions.device_type,
    COUNT(DISTINCT website_sessions.website_session_id) as sessions,
    COUNT(DISTINCT orders.order_id) as orders,
	COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100 AS session_to_order_conv_pctg
FROM website_sessions

LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id

WHERE website_sessions.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1
ORDER BY sessions DESC;
/* By 2012-05-11, desktop has a almost 4 times higher session to order conversion rate compared to mobile device, also a higher sessions.
	This means that the company should increase their bid on desktop */

 -- Traffic Source Segment Trending
 SELECT
    MIN(DATE(created_at)) AS week_start,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions

WHERE created_at < '2012-06-09' AND created_at > '2012-04-15'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	WEEK(created_at)
/* The data shows that after 2012-04-15, the desktop sessions has went up significantly after the bid went up, and the mobile session slightly decreases */











    