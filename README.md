# 📱 Instagram Clone — SQL Data Analysis

A complete SQL-based analysis project on an **Instagram Clone database**, 
solving 13+ real-world business problems using advanced SQL techniques.

> Built using only MySQL — no BI tools, no Python.  
> Just SQL pushed to its full analytical potential.

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `ravi_ig_clone_solution_.sql` | All SQL queries — objective & subjective |
| `ravikant_sql_report.docx` | Detailed findings & business insights report |
| `ravi_sql_ppt_updated.pptx` | Executive presentation of key results |

---

## 🔍 Business Problems Solved

| # | Problem Statement |
|---|------------------|
| Q1 | Null & Duplicate value detection |
| Q2 | Distribution of user activity levels |
| Q3 | Average tags per post |
| Q4 | Top users by engagement (likes + comments) |
| Q5 | Users with highest followers & following |
| Q6 | Avg. engagement rate per post per user |
| Q7 | Users who never liked any post |
| Q8 | Hashtag performance for ad campaigns |
| Q9 | Correlation between activity levels & content types |
| Q10 | Total likes, comments & tags per user |
| Q11 | Monthly engagement ranking using RANK() |
| Q12 | Hashtags with highest avg. likes (CTE) |
| Q13 | Mutual follow detection |

---

## 🧮 Advanced SQL Concepts Used

| Concept | Usage |
|---------|-------|
| `JOIN (LEFT, INNER, SELF)` | Linking users, photos, likes, comments, follows |
| `CTEs (WITH clause)` | Multi-step logic for segmentation & ranking |
| `Window Functions` | `RANK() OVER()` for monthly engagement ranking |
| `CASE WHEN` | Activity classification & reward tier logic |
| `SUBQUERIES` | Nested logic for hashtag & tag analysis |
| `GROUP BY + HAVING` | Aggregation with filtered conditions |
| `COALESCE & NULLIF` | Handling NULL values & division by zero |
| `DATE_SUB & NOW()` | Time-based filtering for monthly queries |
| `COUNT DISTINCT` | Accurate deduplication across joins |

---

## 💡 Key Business Insights

- Identified **inactive users** for re-engagement campaigns
- Ranked **top influencer candidates** by followers & engagement
- Segmented users into: `High Value`, `Highly Engaged New Creators`,
  `Active Moderate`, `Low Engagement`, `Inactive`
- Detected **mutual follow pairs** for relationship mapping
- Analyzed **hashtag performance** to optimize ad targeting

---

## 🗄️ Database Schema

**Tables Used:**
`users` · `photos` · `comments` · `likes` · `follows` · `tags` · `photo_tags`

---

## 🛠️ Tools Used
`MySQL` `SQL Joins` `CTEs` `Window Functions` `Subqueries`  
`Aggregate Functions` `Data Cleaning` `Business Analysis`

---

## 💡 Key Takeaway
This project shows that SQL alone — when applied with depth —  
can answer complex business questions without any additional tools
