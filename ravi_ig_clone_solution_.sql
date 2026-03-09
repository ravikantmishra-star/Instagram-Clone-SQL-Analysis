use ig_clone;
SHOW TABLES;

SELECT * FROM users;
SELECT * FROM photos;
SELECT * FROM comments;
SELECT * FROM likes;
SELECT * FROM follows;
SELECT * FROM tags;
SELECT * FROM photo_tags;

-- Q1: Tables with null or duplicate values?
-- null check:
SELECT *
FROM users
WHERE username IS NULL
OR id IS NULL
OR created_at IS NULL;

-- for duplicates:
SELECT username, COUNT(*)
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- Q2: Distribution of user activity
WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        COALESCE(COUNT(DISTINCT p.id), 0) AS total_posts,
        COALESCE(COUNT(DISTINCT l.photo_id), 0) AS total_likes,
        COALESCE(COUNT(DISTINCT c.id), 0) AS total_comments
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    GROUP BY u.id
)

SELECT 
    CASE 
        WHEN (total_posts + total_likes + total_comments) = 0 THEN 'Inactive'
        WHEN (total_posts + total_likes + total_comments) BETWEEN 1 AND 10 THEN 'Low Activity'
        WHEN (total_posts + total_likes + total_comments) BETWEEN 11 AND 50 THEN 'Medium Activity'
        ELSE 'High Activity'
    END AS activity_level,
    COUNT(*) AS user_count
FROM user_activity
GROUP BY activity_level
ORDER BY user_count DESC;

-- Q3: Average tags per post
SELECT AVG(tag_count) AS avg_tags_per_post
FROM (
    SELECT photo_id, COUNT(tag_id) AS tag_count
    FROM photo_tags
    GROUP BY photo_id
) AS tag_data;

-- Q4: Top users by engagement, rank them
SELECT 
u.id as user_id,
u.username,
COUNT(DISTINCT l.photo_id) AS total_likes,
COUNT(DISTINCT c.id) AS total_comments,
COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) AS engagement
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id
ORDER BY engagement DESC;

-- Q5: Users with highest followers and following
-- Followers:
SELECT u.id as user_id, u.username, count(f.followee_id) AS total_followers
FROM users u
JOIN follows f
ON u.id=f.followee_id
GROUP BY u.id,u.username
ORDER BY total_followers DESC
LIMIT 10;

-- Following:
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(f.followee_id) AS total_followings
FROM users u
JOIN follows f 
    ON u.id = f.follower_id
GROUP BY u.id, u.username
ORDER BY total_followings DESC
LIMIT 10;


-- Q6: Each users average engagenent rate per post
SELECT 
    u.id as user_id,
    u.username,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    ROUND(
        (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) 
        / COUNT(DISTINCT p.id), 2
    ) AS avg_engagement_per_post
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id
HAVING total_posts > 0
ORDER BY avg_engagement_per_post DESC;

-- Q7: Users Who Never Liked Any Post
SELECT 
    u.id AS user_id,
    u.username
FROM users u
LEFT JOIN likes l
    ON u.id = l.user_id
WHERE l.user_id IS NULL;


-- Q8: Leverage User-Generated Content (post,hastags,photo tags) to create more personalizedand engaging ad campaign
SELECT 
    t.tag_name,
    ROUND(AVG(tag_usage), 2) AS avg_tag_usage
FROM (
    SELECT 
        pt.tag_id,
        COUNT(pt.photo_id) AS tag_usage
    FROM photo_tags pt
    GROUP BY pt.tag_id
) hastag
JOIN tags t 
    ON hastag.tag_id = t.id
GROUP BY t.tag_name
ORDER BY avg_tag_usage DESC;

-- Q9: Correlation Between user activity levels and specific content types
WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        COUNT(DISTINCT p.id) +
        COUNT(DISTINCT l.photo_id) +
        COUNT(DISTINCT c.id) AS total_activity
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    GROUP BY u.id
),

activity_level AS (
    SELECT 
        user_id,
        CASE 
            WHEN total_activity = 0 THEN 'Inactive'
            WHEN total_activity BETWEEN 1 AND 10 THEN 'Low Activity'
            WHEN total_activity BETWEEN 11 AND 50 THEN 'Medium Activity'
            ELSE 'High Activity'
        END AS activity_group
    FROM user_activity
)

SELECT 
    a.activity_group,
    t.tag_name,
    COUNT(DISTINCT a.user_id) AS active_users,
    COUNT(p.id) AS total_posts
FROM activity_level a
JOIN photos p ON a.user_id = p.user_id
JOIN photo_tags pt ON p.id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
GROUP BY a.activity_group, t.tag_name
ORDER BY a.activity_group, total_posts DESC;

-- Q10: Total Likes, Comments & Tags for Each User
SELECT
    u.id as user_id, u.username,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    COUNT(DISTINCT pt.tag_id) AS total_tags
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
LEFT JOIN photo_tags pt ON p.id = pt.photo_id
GROUP BY u.id, u.username;

-- Q_11: Rank users based on total engagement (likes + comments + shares) over a month
SELECT 
    u.id,
    u.username,
    COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) AS total_engagement,
    RANK() OVER (ORDER BY 
        COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) DESC
    ) AS engagement_rank
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
WHERE p.created_dat >= DATE_SUB(NOW(), INTERVAL 1 MONTH)
GROUP BY u.id, u.username
ORDER BY total_engagement DESC;


-- Q12: Hashtags used in posts with highest average likes (Using CTE)
WITH hashtag_avg_likes AS (
    SELECT 
        t.tag_name,
        COUNT(l.photo_id) / COUNT(DISTINCT p.id) AS avg_likes
    FROM tags t
    JOIN photo_tags pt ON t.id = pt.tag_id
    JOIN photos p ON pt.photo_id = p.id
    LEFT JOIN likes l ON p.id = l.photo_id
    GROUP BY t.tag_name
)
SELECT *
FROM hashtag_avg_likes
ORDER BY avg_likes DESC;


-- Q13: Users who followed someone after being followed by that person (Mutual follow)
SELECT 
    u1.id AS user_id,
    u1.username AS user_name,
    u2.id AS followed_user_id,
    u2.username AS followed_user_name
FROM follows f1
JOIN follows f2
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
JOIN users u1
    ON f1.follower_id = u1.id
JOIN users u2
    ON f1.followee_id = u2.id
WHERE f1.follower_id < f1.followee_id;

   
   -- SUBJECTIVE QUESTION QUERIES
   
   -- Q1: Most Loyal / Valuable Users
   SELECT u.id as user_id, u.username,
       COUNT(DISTINCT p.id) AS total_posts,
       COUNT(DISTINCT l.photo_id) AS total_likes,
       COUNT(DISTINCT c.id) AS total_comments,
       (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) AS total_engagement,
       CASE
       WHEN (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id))>= 300
       THEN 'Gold Creator badges - Featured Progile & Exclusive Benifits'
       WHEN (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id))>= 200
       THEN 'Silver Creator badges - Early Access & Bonus Visibility'
       WHEN (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id))>= 100
       THEN 'Bronze Creator badges - Loyality Badge'
       ELSE 'Rising Creator - Participation in community events'
       END AS reward_category
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
WHERE p.id IS NOT NULL
GROUP BY u.id
ORDER BY total_engagement DESC;

-- Q2: Strategy to Re-Engage Inactive Users

SELECT 
	u.id as  user_id,
    u.username
FROM users u
LEFT JOIN photos p 
    ON u.id = p.user_id
LEFT JOIN likes l 
    ON u.id = l.user_id
LEFT JOIN comments c 
    ON u.id = c.user_id
WHERE p.id IS NULL
  AND l.user_id IS NULL
  AND c.id IS NULL;


-- Q3: Hashtags with Highest Engagement Rates
SELECT 
    t.tag_name,
    COUNT(DISTINCT p.id) AS total_posts,
    COUNT(DISTINCT l.photo_id) AS total_likes,
    COUNT(DISTINCT c.id) AS total_comments,
    (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) AS total_engagement,
    (COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id)) 
        / COUNT(DISTINCT p.id) AS engagement_rate
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
JOIN photos p ON pt.photo_id = p.id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY t.id
ORDER BY engagement_rate DESC;

-- Q4: Engagement Patterns Based on Posting Time / Demographics
WITH post_level AS (
    SELECT
        p.user_id,
        p.id AS photo_id,
        COUNT(DISTINCT l.user_id) AS likes_per_post,
        COUNT(DISTINCT c.id) AS comments_per_post
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    LEFT JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.id, p.user_id
)

SELECT
    u.id AS user_id,
    u.username,
    COUNT(pl.photo_id) AS total_posts,
    ROUND(AVG(pl.likes_per_post), 2) AS avg_likes_per_post,
    ROUND(AVG(pl.comments_per_post), 2) AS avg_comments_per_post,
    ROUND(AVG(pl.likes_per_post + pl.comments_per_post), 2) AS avg_engagement_per_post
FROM users u
LEFT JOIN post_level pl
    ON u.id = pl.user_id
GROUP BY u.id, u.username
ORDER BY avg_engagement_per_post DESC;

-- Q5: Ideal candidates for influencer marketing campaigns
WITH follower_count AS (
    SELECT 
        followee_id AS user_id,
        COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
),
post_level AS (
    SELECT
        p.id AS photo_id,
        p.user_id,
        COUNT(DISTINCT l.user_id) AS likes_per_post,
        COUNT(DISTINCT c.id) AS comments_per_post
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    LEFT JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.id, p.user_id
),
avg_engagement AS (
    SELECT
        user_id,
        ROUND(AVG(likes_per_post + comments_per_post), 2) 
            AS avg_engagement_per_post
    FROM post_level
    GROUP BY user_id
)

SELECT
    u.id AS user_id,
    u.username,
    COALESCE(fc.total_followers, 0) AS total_followers,
    COALESCE(ae.avg_engagement_per_post, 0) AS avg_engagement_per_post
FROM users u
LEFT JOIN follower_count fc 
    ON u.id = fc.user_id
LEFT JOIN avg_engagement ae 
    ON u.id = ae.user_id
ORDER BY total_followers DESC, avg_engagement_per_post DESC;


-- Q6: User Segmentation based on engagement  and activity
WITH post_level AS (
    SELECT
        p.id AS photo_id,
        p.user_id,
        COUNT(DISTINCT l.user_id) AS likes_per_post,
        COUNT(DISTINCT c.id) AS comments_per_post,
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS engagement_per_post
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    LEFT JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.id, p.user_id
),

user_metrics AS (
    SELECT
        u.id AS user_id,
        u.username,
        COUNT(pl.photo_id) AS total_posts,
        ROUND(AVG(pl.engagement_per_post), 2) AS avg_engagement_per_post
    FROM users u
    LEFT JOIN post_level pl 
        ON u.id = pl.user_id
    GROUP BY u.id, u.username
),

segmented_users AS (
    SELECT
        user_id,
        username,
        total_posts,
        COALESCE(avg_engagement_per_post, 0) AS avg_engagement_per_post,
        CASE
            WHEN total_posts >= 5 AND avg_engagement_per_post >= 35 
                THEN 'High Value Users'
            WHEN total_posts < 5 AND avg_engagement_per_post >= 35 
                THEN 'Highly Engaged New Creators'
            WHEN total_posts >= 5 
                 AND avg_engagement_per_post BETWEEN 25 AND 34.99
                THEN 'Active Moderate Engagement Users'
            WHEN total_posts > 0 
                 AND avg_engagement_per_post < 25
                THEN 'Low Engagement Users'
            ELSE 'Inactive Users'
        END AS user_segment
    FROM user_metrics
)

SELECT
    user_segment,
    COUNT(*) AS total_users,
    ROUND(AVG(total_posts), 2) AS avg_posts_per_user,
    ROUND(AVG(avg_engagement_per_post), 2) AS avg_engagement_per_user
FROM segmented_users
GROUP BY user_segment
ORDER BY total_users DESC;

-- Q7: Measuring Campaign Effectiveness
SELECT
    campaign_id,
    impressions,
    clicks,
    conversions,
    ROUND((clicks / NULLIF(impressions, 0)) * 100, 2) 
        AS ctr_percentage,
    ROUND((conversions / NULLIF(clicks, 0)) * 100, 2) 
        AS conversion_rate_percentage,
    ROUND((conversions / NULLIF(impressions, 0)) * 100, 2) 
        AS overall_conversion_percentage
FROM ad_campaigns;

-- Q8: Identifying Brand Ambassadors
WITH post_level AS (
    SELECT
        p.id AS photo_id,
        p.user_id,
        COUNT(DISTINCT l.user_id) AS likes_per_post,
        COUNT(DISTINCT c.id) AS comments_per_post,
        (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS engagement_per_post
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    LEFT JOIN comments c 
        ON p.id = c.photo_id
    GROUP BY p.id, p.user_id
),

user_activity AS (
    SELECT
        u.id AS user_id,
        u.username,
        COUNT(pl.photo_id) AS total_posts,
        ROUND(AVG(pl.engagement_per_post), 2) AS avg_engagement_per_post,
        SUM(pl.engagement_per_post) AS total_engagement
    FROM users u
    LEFT JOIN post_level pl 
        ON u.id = pl.user_id
    GROUP BY u.id, u.username
)

SELECT
    username,
    total_posts,
    total_engagement,
    avg_engagement_per_post
FROM user_activity
ORDER BY avg_engagement_per_post DESC, total_posts DESC;

-- Q10: Update “Like” to “Heart” in Database
UPDATE User_Interactions
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';



   