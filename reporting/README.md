# Campaign Effectiveness Reporting System

This reporting system analyzes marketing campaign effectiveness by connecting targeting data with customer information, web traffic, and ad exposure data.

## Data Model

The system is built on five primary data tables:

NOTE: This data model defines the absolute minimum required data points. It can and will be expanded as requirements evolve.

1. **targets** - People selected for targeting in marketing campaigns
   - `mpid` - Person ID (primary identifier)

2. **target_master** - Master pool of all potential targets
   - `mpid` - Person ID
   - `hhid` - Household ID (connects to digital behavior)

3. **customers** - Current customer database
   - `mpid` - Person ID
   - `hhid` - Household ID
   - `interaction_date` - Date of customer interaction
   
4. **web_traffic** - Website visit data
   - `hhid` - Household ID
   - `visit_date` - Date of website visit
   - `url` - URL visited

5. **ad_log** - Digital advertising exposure data
   - `hhid` - Household ID
   - `ad_date` - Date ad was served
   - `campaign_name` - Name of the campaign
   - `click` - 0 or 1 indicating a click-through 
   

## Methodology

The system's data tracking approach is structured across three levels:

### 1. Digital Advertising (Household Level)
- IP addresses and digital identifiers are typically household-based
- Multiple devices in a household share the same IP
- Ad targeting systems work at the household level

### 2. Web Traffic (Household Level)
- Website analytics typically track visits by IP/household
- Multiple household members might use the same devices
- It's difficult to distinguish individual users within a household

### 3. Customer Tracking (Individual Level)
- We need to attribute conversions to specific targeted individuals
- This prevents false attribution (e.g., if a non-targeted household member became a customer)
- It maintains accurate ROI measurement for campaigns

This multi-level approach ensures we're measuring the true effectiveness of a campaign while acknowledging the limitations of digital tracking at the household level.

## Customer Classification Logic

The system classifies individuals into three categories:

- **Ad-generated customer** - Individuals who meet any of these criteria:
  - Exist in the customer table AND EITHER:
    - Their first interaction date came after seeing the ad (true new customer) OR
    - They were dormant customers who re-engaged, meaning:
      - Their last interaction was more than 24 months before seeing the ad (truly dormant)
      - AND they had a new interaction after seeing the ad (re-engaged)
  
- **Existing customer** - Individuals who:
  - Exist in the customer table AND
  - Don't meet the criteria for "ad-generated customer"
  
- **Non-customer** - Individuals who:
  - Were targeted and received ads
  - Don't exist in the customer table

## Core View

The system is built around a consolidated analysis view:

TODO: figure out a better way to handle interaction dates. In this example we use min and max of the same date but we could have a true first and last date

## Implementation Notes

The core view is designed to work with any client's data structure by mapping their specific field names to our standardized model. For example:
- The data model uses generic terms (e.g., `interaction_date`)
- The implementation maps client-specific fields (e.g., `application_date`) to our generic model
- The core view standardizes these into consistent output fields (`first_interaction_date`, `last_interaction_date`)

This mapping allows the reporting system to work with different types of customer interactions while maintaining consistent output fields for all reports.

## Core View Template

Replace the following placeholders with client-specific values:
- `{CLIENT_NAME}` - Name of the client for the view
- `{CLIENT_CAMPAIGN_PATTERN}` - Pattern to match client's campaign names
- `{CLIENT_WEBSITE_DOMAIN}` - Client's website domain pattern
- `{CLIENT_START_DATE}` - Analysis start date in YYYYMMDD format (optional)
- `{CLIENT_END_DATE}` - Analysis end date in YYYYMMDD format (optional)

```sql
CREATE VIEW {CLIENT_NAME}_campaign_analysis AS
WITH first_impressions AS (
  SELECT 
    a.zip11 as hhid,
    a.campaignname,
    MAX(a.click) as click,
    MIN(date_format(cast(substr(a.impression_time,1,10) as timestamp), '%Y%m%d')) AS first_ad_date,
    MIN(a.impression_time) as first_impression_time
  FROM stirista_impression_log a
  WHERE a.campaignname LIKE '{CLIENT_CAMPAIGN_PATTERN}'
  GROUP BY a.zip11, a.campaignname
),
formatted_interactions AS (
  SELECT
    mpid,
    zip,
    zip4,
    dpc,
    -- Format the interaction date to YYYYMMDD
    DATE_FORMAT(DATE_PARSE(application_date, '%c/%e/%Y %l:%i:%s %p'), '%Y%m%d') as interaction_date
  FROM ac_mn_job_applicants_mpid_20250317
),
customer_interactions AS (
SELECT
    a.mpid,
    concat(a.zip,a.zip4,substr(a.dpc,1,2)) as hhid,
    MIN(a.interaction_date) AS first_interaction_date,
    MAX(a.interaction_date) AS last_interaction_date,
    -- Get the last interaction within 24 months of each interaction
    MAX(b.interaction_date) as last_interaction_within_24m
FROM formatted_interactions a
LEFT JOIN formatted_interactions b
    ON a.mpid = b.mpid
    -- this interaction is later than the other interaction
    AND a.interaction_date > b.interaction_date
    -- the second interaction is no more than 24 months older than the a side
    AND date_parse(a.interaction_date, '%Y%m%d') - interval '24' month >= 
        date_parse(b.interaction_date, '%Y%m%d')
GROUP BY a.mpid, concat(a.zip,a.zip4,substr(a.dpc,1,2))
),
household_ids AS (
  SELECT 
    mpid,
    zip11 as hhid
  FROM stirista_master_20250218
)
SELECT
  t.mpid, 
  ci.first_interaction_date,
  ci.last_interaction_date,
  ci.last_interaction_within_24m,
  tm.hhid,
  fi.first_ad_date AS ad_date,
  fi.campaignname,
  w.visit_date,
  CASE 
    WHEN ci.mpid IS NULL THEN 'Non-customer'
    WHEN ci.first_interaction_date >= fi.first_ad_date THEN 'Ad-generated customer'
    WHEN ci.last_interaction_within_24m < date_format(date_add('month', -24, cast(fi.first_ad_date as timestamp)), '%Y%m%d') 
         AND ci.last_interaction_date >= fi.first_ad_date THEN 'Ad-generated customer'
    ELSE 'Existing customer'
  END AS customer_status
FROM gh_build.ac_orders_20250320 t
JOIN household_ids tm ON t.mpid = tm.mpid
LEFT JOIN customer_interactions ci ON t.mpid = ci.mpid
LEFT JOIN first_impressions fi ON tm.hhid = fi.hhid
LEFT JOIN (
    SELECT 
        zip11,
        MIN(date_format(cast(time_stamp as timestamp), '%Y%m%d')) as visit_date
    FROM stirista_vig_data
    WHERE domain LIKE '{CLIENT_WEBSITE_DOMAIN}'
    GROUP BY zip11
) w ON tm.hhid = w.zip11 
    AND w.visit_date >= fi.first_ad_date;
```

### Example Usage:
```sql
-- For a client named "acme" targeting "ACME_*" campaigns and website "*.acme.com"
CREATE VIEW acme_campaign_analysis AS
WITH first_impressions AS (
  SELECT 
    a.zip11 as hhid,
    a.campaignname,
    MAX(a.click) as click,
    MIN(date_format(cast(substr(a.impression_time,1,10) as timestamp), '%Y%m%d')) AS first_ad_date,
    MIN(a.impression_time) as first_impression_time
  FROM stirista_impression_log a
  WHERE a.campaignname LIKE 'ACME_%'
  GROUP BY a.zip11, a.campaignname
)
...
LEFT JOIN stirista_vig_data w ON tm.hhid = w.zip11 
  AND date_format(cast(w.time_stamp as timestamp), '%Y%m%d') >= fi.first_ad_date
  AND w.domain LIKE '%.acme.com';
```

## Understanding the Campaign Analysis View

This analysis view is the cornerstone of the marketing effectiveness measurement. 

### Data Integration Process

The view connects five critical data sources to create a complete picture of the marketing journey:

1. **Target Data (mpid for all orders)**: Provides information about individuals we've specifically targeted with marketing.

2. **Master Data (all available targets)**: Connects individual identifiers (mpid) to household identifiers (zip11) allowing us to bridge personal and household-level data.

3. **Customer Data (supplied by cusomer)**: Contains information about when individuals became customers through their application dates.

4. **Ad Impression Data (details about ads served)**: Records when and which ads were shown to specific households.

5. **Website Visit Data (web traffic data)**: Tracks when households visited our website after ad exposure.

### First Impressions Tracking

A critical component of this view is the `first_impressions` subquery which:

- Groups ad impressions by household ID (zip11) and campaign name
- Identifies the first time each household was exposed to each campaign's ads
- Tracks if the household ever clicked on any impression for the campaign using MAX(click)
- Ensures customer classification is based on the initial ad exposure rather than subsequent ones
- Provides accurate attribution of customer behavior to the first relevant marketing touchpoint

The click tracking approach:
- Uses MAX(click) to identify if a household ever clicked on any impression
- Returns 1 if they clicked on any impression in the campaign
- Returns 0 if they never clicked on any impression
- Allows us to analyze the relationship between clicks and customer behavior while maintaining first-impression attribution

This approach prevents over-attributing customer behavior to later ad impressions when the initial exposure may have been the actual catalyst for action, while still capturing whether the household engaged through clicks at any point in the campaign.

### Date Standardization

The system handles client-specific date formats through a dedicated `formatted_interactions` CTE that:
- Takes raw interaction dates from the client's data
- Parses them from their original format (e.g., '%c/%e/%Y %l:%i:%s %p')
- Converts them to a standardized YYYYMMDD format
- Makes the rest of the system independent of client-specific date formats

### Customer Interactions Processing

The `customer_interactions` subquery processes the standardized interaction data to:
- Track the first and last interaction dates for each customer
- Create household IDs by combining zip, zip4, and dpc fields for household-level matching
- Identify the last interaction within 24 months of each interaction using a self-join pattern:
  - For each interaction, finds the most recent previous interaction that's within 24 months
  - If no such interaction exists, indicates the customer was dormant at that point

This processing is essential for accurately classifying customers based on their interaction history and determining whether they were influenced by the advertising campaign.

### Customer Classification Logic

Each targeted individual is classified into one of three categories:

1. **"Non-customer"**: Individuals who don't exist in the customer table (`ci.mpid IS NULL`), meaning they've never converted.

2. **"Ad-generated customer"**: Individuals who meet any of these criteria:
   - Their first interaction date came after seeing our first ad impression (true new customer acquisition)
   - They were dormant customers (no interaction within 24 months before the ad) who then re-engaged after seeing the ad

3. **"Existing customer"**: Active customers who saw an ad but don't qualify as "ad-generated" (they were already engaged customers before the ad campaign).

### The Value of This View

This consolidated view enables us to:

- Track which ads drive true new customer acquisition
- Identify which campaigns are effective at re-engaging dormant customers
- Compare campaign effectiveness across different audience segments
- Analyze the customer journey from first ad exposure to website visit to conversion
- Calculate critical metrics like conversion rates and visit rates without complex joins

By tracking first impressions and precisely categorizing customer responses, this view provides a foundation for comprehensive marketing performance analysis that connects targeting, ad exposure, site engagement, and customer conversion in a single analytical framework.

### Web Traffic Integration

The system integrates web traffic data as an optional enrichment layer that does not affect core customer classification logic:

- **Data Source**: Website visit data 
  - Contains visit timestamps, domains, and URLs
  - Matched to customers via household ID (zip11)
  - Filtered to only include visits to client's website domain

- **Processing Approach**:
  - Uses a subquery to get only the first website visit for each household
  - Prevents row multiplication from multiple visits by the same household
  - Only considers visits that occurred after first ad exposure
  - Web traffic presence/absence has no impact on customer classification

Example of web traffic processing:
```sql
LEFT JOIN (
    SELECT 
        zip11,
        MIN(date_format(cast(time_stamp as timestamp), '%Y%m%d')) as visit_date
    FROM stirista_vig_data
    WHERE domain LIKE '{CLIENT_WEBSITE_DOMAIN}'
    GROUP BY zip11
) w ON tm.hhid = w.zip11 
    AND w.visit_date >= fi.first_ad_date
```

### Handling Targets in Multiple Campaigns

The reporting system handles targets that appear in multiple campaigns through two types of reports:

1. **Campaign-specific Reports**: 
   - Show how each campaign performed independently
   - May count the same person multiple times if they were targeted in multiple campaigns
   - Useful for campaign-level analysis and optimization
   - Examples: Target-to-Acquisition Conversion Rates, Campaign Performance Analysis

2. **Unique Customer Reports**:
   - Show the true number of unique customers generated
   - Count each customer only once, typically attributed to their first generating campaign
   - Include counts of how many campaigns targeted each customer
   - Examples: Monthly unique customer counts, Unique customer list

This dual approach ensures we can:
- Measure individual campaign performance accurately
- Track overall program effectiveness
- Understand the extent of multiple targeting
- Avoid over-counting unique customer acquisitions

The following reports have been specifically designed to handle multiple campaign targeting:

- **Ad-generated Customer Counts**: Shows both campaign-specific and unique monthly totals
- **Time-Series Analysis**: Provides both campaign-specific and unique customer metrics
- **Campaign-Generated Customer List**: Offers both full campaign relationships and unique customer views

Example of unique customer tracking:
```sql
WITH first_customer_appearance AS (
    SELECT 
        mpid,
        customer_status,
        MIN(ad_date) as first_ad_date
    FROM campaign_analysis
    WHERE customer_status = 'Ad-generated customer'
    GROUP BY mpid, customer_status
)
```

## SQL Queries for Campaign Reporting Framework

### 1. Customer Acquisition Dashboard

#### Ad-generated Customer Counts
This report provides two views of customer acquisition:
1. Campaign-specific counts showing how many customers each campaign generated, including existing and non-customers
2. Monthly unique customer counts that show the true number of new customers, counting each customer only once in their first generating month

```sql
-- Campaign-specific customer counts with click-through breakdown
SELECT 
    campaignname,
    COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure') AS month,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' AND click = 1 THEN mpid END) AS ad_generated_customers_with_click,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' AND click = 0 THEN mpid END) AS ad_generated_customers_no_click,
    COUNT(DISTINCT CASE WHEN customer_status = 'Existing customer' AND click = 1 THEN mpid END) AS existing_customers_with_click,
    COUNT(DISTINCT CASE WHEN customer_status = 'Existing customer' AND click = 0 THEN mpid END) AS existing_customers_no_click,
    COUNT(DISTINCT CASE WHEN customer_status = 'Non-customer' AND click = 1 THEN mpid END) AS non_customers_with_click,
    COUNT(DISTINCT CASE WHEN customer_status = 'Non-customer' AND click = 0 THEN mpid END) AS non_customers_no_click,
    COUNT(DISTINCT mpid) AS total_targets
FROM campaign_analysis
GROUP BY campaignname, COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure')
ORDER BY campaignname, month;

-- Monthly unique customer counts (counting each customer only once in their first generating month)
WITH first_customer_appearance AS (
    SELECT 
        mpid,
        customer_status,
        MIN(ad_date) as first_ad_date
    FROM campaign_analysis
    WHERE customer_status = 'Ad-generated customer'
    GROUP BY mpid, customer_status
)
SELECT 
    COALESCE(concat(substr(first_ad_date, 1, 4), '-', substr(first_ad_date, 5, 2)), 'No Ad Exposure') AS month,
    COUNT(DISTINCT fca.mpid) AS unique_ad_generated_customers,
    COUNT(DISTINCT ca.campaignname) AS contributing_campaigns
FROM first_customer_appearance fca
JOIN campaign_analysis ca ON fca.mpid = ca.mpid 
    AND ca.customer_status = 'Ad-generated customer'
GROUP BY COALESCE(concat(substr(first_ad_date, 1, 4), '-', substr(first_ad_date, 5, 2)), 'No Ad Exposure')
ORDER BY month;
```

#### Target-to-Acquisition Conversion Rates
This report calculates the conversion rate for each campaign by comparing the number of ad-generated customers to the total number of targets, providing a clear measure of campaign effectiveness.

```sql
-- Conversion rates by campaign
SELECT 
    campaignname,
    COUNT(DISTINCT mpid) AS targets,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS acquisitions,
    CAST(COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS DECIMAL(10,2)) * 100.0 / 
        CAST(COUNT(DISTINCT mpid) AS DECIMAL(10,2)) AS conversion_rate
FROM campaign_analysis
GROUP BY campaignname
ORDER BY conversion_rate DESC;
```

### 2. Campaign Performance Reports

#### Ad Exposure Metrics by Customer Status
This report analyzes how different customer segments (ad-generated, existing, and non-customers) engage with website visits after ad exposure, helping understand the impact of ads across all customer types.

```sql
-- Ad exposure and engagement by campaign, customer status, and click-through
SELECT 
    campaignname,
    customer_status,
    click,
    COUNT(DISTINCT hhid) AS unique_households,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL THEN hhid END) AS households_with_site_visit,
    CAST(COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL THEN hhid END) AS DECIMAL(10,2)) * 100.0 / 
        NULLIF(CAST(COUNT(DISTINCT hhid) AS DECIMAL(10,2)), 0) AS visit_rate
FROM campaign_analysis
GROUP BY campaignname, customer_status, click
ORDER BY campaignname, customer_status, click;
```

#### Website Engagement Post-Ad
This report measures the effectiveness of ads in driving website traffic by tracking:
- How many households were served ads
- How many of those households visited the website after seeing an ad
- The percentage of ad-served households that engaged with the website

```sql
-- Campaign performance metrics with click-through breakdown
SELECT 
    campaignname,
    COUNT(DISTINCT hhid) AS households_reached,
    COUNT(DISTINCT CASE WHEN click = 1 THEN hhid END) AS households_with_clicks,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' AND click = 1 THEN mpid END) AS acquisitions_with_click,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' AND click = 0 THEN mpid END) AS acquisitions_no_click,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL AND click = 1 THEN hhid END) AS website_visitors_with_click,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL AND click = 0 THEN hhid END) AS website_visitors_no_click,
    CAST(COUNT(DISTINCT CASE WHEN click = 1 THEN hhid END) AS DOUBLE) * 100.0 / 
        NULLIF(CAST(COUNT(DISTINCT hhid) AS DOUBLE), 0) AS click_through_rate
FROM campaign_analysis
GROUP BY campaignname
ORDER BY campaignname;
```

This report shows:
- households_served_ads: Number of households that were shown ads in each campaign
- households_visited_after_ad: Number of those households that visited the website after seeing an ad
- pct_households_visited_after_ad: Percentage of ad-served households that visited the website after exposure

#### Campaign Performance Analysis
This report provides a comprehensive view of campaign performance by tracking:
- Total households reached
- Number of customer acquisitions
- Website visitor counts
- Website visit rates

```sql
-- Performance metrics by campaign
SELECT 
    campaignname,
    COUNT(DISTINCT hhid) AS households_reached,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS acquisitions,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL THEN hhid END) AS website_visitors,
    CAST(COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL THEN hhid END) AS DOUBLE) * 100.0 / 
        CASE WHEN COUNT(DISTINCT hhid) = 0 THEN NULL ELSE CAST(COUNT(DISTINCT hhid) AS DOUBLE) END AS website_visit_rate
FROM campaign_analysis
GROUP BY campaignname
ORDER BY campaignname;
```

### 3. Targeting Effectiveness Reports

#### Campaign Effectiveness
This report provides a detailed breakdown of campaign performance metrics including:
- Number of targets and households reached
- Website visitor counts
- Customer acquisition numbers and rates
- All metrics are calculated per campaign for easy comparison

```sql
-- Performance by campaign
SELECT 
    campaignname,
    COUNT(DISTINCT mpid) AS targets,
    COUNT(DISTINCT hhid) AS households_reached,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL AND visit_date >= ad_date THEN hhid END) AS website_visitors,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS acquisitions,
    CAST(COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS DECIMAL(10,2)) * 100.0 / 
        CAST(COUNT(DISTINCT mpid) AS DECIMAL(10,2)) AS acquisition_rate
FROM campaign_analysis
GROUP BY campaignname
ORDER BY acquisition_rate DESC;
```

#### Re-engagement Analysis
This report specifically focuses on dormant customers (those without activity for 24+ months) to measure:
- How many dormant customers were targeted
- How many re-engaged after seeing an ad
- The re-engagement rate by campaign and month
- The timing of their last interaction before becoming dormant

```sql
-- Re-engagement of dormant customers by campaign
SELECT 
    campaignname,
    COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure') AS month,
    COUNT(DISTINCT mpid) AS dormant_customers_targeted,
    COUNT(DISTINCT CASE WHEN last_interaction_date > ad_date THEN mpid END) AS dormant_customers_reengaged,
    CAST(COUNT(DISTINCT CASE WHEN last_interaction_date > ad_date THEN mpid END) AS DECIMAL(10,2)) * 100.0 / 
        NULLIF(CAST(COUNT(DISTINCT mpid) AS DECIMAL(10,2)), 0) 
        AS reengagement_rate,
    MAX(last_interaction_date) AS last_interaction_date,
    MAX(last_interaction_within_24m) AS last_encounter_before_ad
FROM campaign_analysis
WHERE customer_status = 'Ad-generated customer'
  AND last_interaction_within_24m < date_format(date_add('month', -24, cast(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2), '-01') as date)), '%Y-%m-%d')
  AND last_interaction_date < date_format(date_add('month', -24, cast(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2), '-01') as date)), '%Y-%m-%d')
  AND last_interaction_date > ad_date
GROUP BY campaignname, COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure')
ORDER BY campaignname, month;
```

### 4. Time-Series Analysis
This report tracks campaign performance over time, showing:
- Monthly targets and households reached
- Website visitor trends
- New customer acquisition patterns
- All metrics broken down by campaign and month

```sql
-- Campaign-specific monthly performance tracking
SELECT 
    campaignname,
    COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure') AS month,
    COUNT(DISTINCT mpid) AS targets,
    COUNT(DISTINCT hhid) AS households_reached,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL AND visit_date >= ad_date THEN hhid END) AS website_visitors,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS new_customers_by_campaign
FROM campaign_analysis
GROUP BY campaignname, COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure')
ORDER BY campaignname, month;
```

### 5. Campaign Comparison Reports
This report enables direct comparison of campaigns over time by tracking:
- Household reach
- New customer acquisition
- Website visitor engagement
- All metrics organized by campaign and month for trend analysis

```sql
-- Campaign comparison over time
SELECT 
    campaignname,
    COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure') AS month,
    COUNT(DISTINCT hhid) AS households_reached,
    COUNT(DISTINCT CASE WHEN customer_status = 'Ad-generated customer' THEN mpid END) AS new_customers,
    COUNT(DISTINCT CASE WHEN visit_date IS NOT NULL AND visit_date >= ad_date THEN hhid END) AS website_visitors
FROM campaign_analysis
GROUP BY campaignname, COALESCE(concat(substr(ad_date, 1, 4), '-', substr(ad_date, 5, 2)), 'No Ad Exposure')
ORDER BY campaignname, month;
```

### 6. Customer Details Reports

#### Campaign-Generated Customer List
```sql
-- Campaign-specific list (shows all campaign-customer relationships)
SELECT 
    campaignname,
    mpid,
    customer_status,
    ad_date,
    last_interaction_date,
    visit_date,
    hhid
FROM campaign_analysis
WHERE customer_status = 'Ad-generated customer'
ORDER BY campaignname, ad_date, mpid;

-- Unique customer list (shows each customer only once, with their first generating campaign)
SELECT 
    first_campaign.campaignname as first_generating_campaign,
    first_campaign.mpid,
    first_campaign.customer_status,
    first_campaign.ad_date as first_ad_date,
    first_campaign.last_interaction_date,
    first_campaign.visit_date,
    first_campaign.hhid,
    COUNT(all_campaigns.campaignname) as number_of_campaigns_targeted
FROM campaign_analysis first_campaign
JOIN (
    SELECT mpid, campaignname
    FROM campaign_analysis
    WHERE customer_status = 'Ad-generated customer'
) all_campaigns ON first_campaign.mpid = all_campaigns.mpid
WHERE first_campaign.customer_status = 'Ad-generated customer'
GROUP BY 
    first_campaign.campaignname,
    first_campaign.mpid,
    first_campaign.customer_status,
    first_campaign.ad_date,
    first_campaign.last_interaction_date,
    first_campaign.visit_date,
    first_campaign.hhid
HAVING first_campaign.ad_date = MIN(first_campaign.ad_date)
ORDER BY first_campaign.ad_date, first_campaign.mpid;
```

This report provides:
- Campaign name that generated the customer
- Customer's MPID (unique identifier)
- Customer status (always 'Ad-generated customer' in this filtered view)
- Date they first saw the ad
- Date of their last interaction
- Date they visited the website (if applicable)
- Household ID (hhid)









