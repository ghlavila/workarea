# Enhanced Campaign Effectiveness Reporting System

This document outlines an enhanced version of the campaign effectiveness reporting system that builds upon the existing architecture while adding new capabilities.

## System Overview

The enhanced system consists of two main components:

1. **Core System** - The existing campaign effectiveness reporting system (as documented in README.md)
2. **Enhanced Layer** - New functionality that extends the core system with additional features

## Enhanced Data Model

### 1. Campaign Configuration
```sql
CREATE TABLE campaign_config (
    campaign_id VARCHAR(50) PRIMARY KEY,
    campaign_name VARCHAR(100),
    audience_name VARCHAR(100),
    customer_code VARCHAR(50),
    billing_code VARCHAR(50),
    royalty_code VARCHAR(50),
    start_date DATE,
    end_date DATE,
    dsp_identifier VARCHAR(50),
    vig_identifier VARCHAR(100),
    attribution_window_days INT,
    success_metric_definitions JSON
);
```

### 2. Campaign Costs
```sql
CREATE TABLE campaign_costs (
    campaign_id VARCHAR(50),
    date DATE,
    spend DECIMAL(10,2),
    currency VARCHAR(3),
    dsp VARCHAR(50),
    creative_id VARCHAR(50),
    platform VARCHAR(20), -- mobile, display, etc.
    FOREIGN KEY (campaign_id) REFERENCES campaign_config(campaign_id)
);
```

### 3. Success Metrics
```sql
CREATE TABLE success_metrics (
    metric_id VARCHAR(50) PRIMARY KEY,
    metric_name VARCHAR(100),
    metric_type VARCHAR(20), -- organization, custom
    audience_definition JSON,
    calculation_logic JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Enhanced Core View

The enhanced system maintains compatibility with the existing core view while adding new capabilities:

```sql
CREATE VIEW enhanced_campaign_analysis AS
WITH base_analysis AS (
    -- Existing campaign analysis logic
    SELECT * FROM campaign_analysis
),
cost_metrics AS (
    SELECT 
        campaign_id,
        date,
        SUM(spend) as daily_spend,
        SUM(CASE WHEN platform = 'mobile' THEN spend ELSE 0 END) as mobile_spend,
        SUM(CASE WHEN platform = 'display' THEN spend ELSE 0 END) as display_spend
    FROM campaign_costs
    GROUP BY campaign_id, date
),
creative_metrics AS (
    SELECT 
        campaign_id,
        creative_id,
        platform,
        COUNT(*) as impressions,
        SUM(spend) as spend
    FROM campaign_costs
    GROUP BY campaign_id, creative_id, platform
)
SELECT 
    b.*,
    c.daily_spend,
    c.mobile_spend,
    c.display_spend,
    cr.creative_id,
    cr.platform,
    cr.impressions as creative_impressions,
    cr.spend as creative_spend
FROM base_analysis b
LEFT JOIN cost_metrics c ON b.campaignname = c.campaign_id AND b.ad_date = c.date
LEFT JOIN creative_metrics cr ON b.campaignname = cr.campaign_id;
```

## New Features

### 1. Configurable Attribution Windows
- Default window: 24 months (maintaining existing behavior)
- Configurable per campaign via campaign_config
- Supports different windows for different types of conversions

### 2. Enhanced Digital Analytics
- Creative-level tracking
- Platform breakdown (mobile vs display)
- DSP-specific metrics
- Cost tracking and ROI calculations

### 3. Success Metrics Framework
- Organization-wide metrics (pre-defined)
- Custom metrics (user-defined)
- Audience-based filtering
- Dynamic metric calculation

### 4. Campaign Cost Tracking
- Daily spend tracking
- Creative-level cost allocation
- Platform-specific spend
- Currency handling
- ROI calculations

## Implementation Phases

### Phase 1: Foundation
1. Create new data tables
2. Implement basic cost tracking
3. Add creative/platform tracking
4. Set up attribution window configuration

### Phase 2: Enhanced Analytics
1. Implement success metrics framework
2. Add custom audience definitions
3. Create dynamic metric calculations
4. Build platform-specific reporting

### Phase 3: Advanced Features
1. Implement ROI calculations
2. Add currency conversion
3. Create advanced audience filtering
4. Build custom metric dashboards

