# Olist E-Commerce Revenue Analysis

## Project Background and Overview

Olist is Brazil's largest department store marketplace, and links small businesses to major e-commerce channels. Since 2015, this platform has let merchants sell products through the Olist Store and ship directly to customers using Olist's logistics partners.

This analysis examines 96,518 orders placed between September 2016 and August 2018. The dataset spans R$21.5 million in revenue across 17 product categories and 16 Brazilian states. It provides a comprehensive look at customer behavior, seller performance, product trends, and logistics.

*This project was conducted in November 2025 and later uploaded to GitHub in December 2025.*

**Key business questions addressed:**

- **Sales:** How has revenue and order volume changed over time? What seasonal patterns show up in the data?
- **Region:** What states bring in the most revenue? How does delivery vary by region?
- **Product Strategy:** Which product categories perform the best? What are the pricing patterns?
- **Customer Satisfaction:** What factors influence customer review scores? How does delivery performance impact satisfaction?
- **Payment Behavior:** How do Brazilian consumers prefer to pay? What is installment use pattern?

**Dataset Information**

**Source:** [Brazilian E-Commerce Public Dataset by Olist - Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

**Provider:** Olist Store

The SQL queries used to inspect and clean the data can be found [here](/sql/02_data_inspection.sql).
The SQL queries used for analysis can be found [here](/sql/03_analysis_queries.sql).

---

## Data Structure & Overview

The database consists of 8 interconnected tables with more than 437,000 records. It captures the transaction cycle from order placement to delivery and review.

### Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│    customers    │       │     orders      │       │   order_items   │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ customer_id (PK)│◄──────│ customer_id (FK)│       │ order_id (PK)   │──────┐
│ customer_unique │       │ order_id (PK)   │◄──────│ order_item_id   │      │
│ customer_zip    │       │ order_status    │       │ product_id (FK) │──┐   │
│ customer_city   │       │ purchase_ts     │       │ seller_id (FK)  │
│ customer_state  │       │ approved_at     │       │ price           │  │   │
└─────────────────┘       │ delivered_ts    │       │ freight_value   │  │   │
                          │ estimated_del   │       └─────────────────┘  │   │
                          └─────────────────┘                            │   │
                                   │                                     │   │
                                   ▼                                     │   │
                          ┌─────────────────┐       ┌─────────────────┐  │   │
                          │    payments     │       │    products     │◄─┘   │
                          ├─────────────────┤       ├─────────────────┤      │
                          │ order_id (FK)   │       │ product_id (PK) │      │
                          │ payment_type    │       │ category_name   │      │
                          │ installments    │       │ weight_g        │      │
                          │ payment_value   │       │ dimensions      │      │
                          └─────────────────┘       └─────────────────┘      │
                                   │                                         │
                                   │               ┌─────────────────┐       │
                          ┌────────┴───────┐       │    sellers      │◄──────┘
                          │    reviews     │       ├─────────────────┤
                          ├────────────────┤       │ seller_id (PK)  │
                          │ review_id (PK) │       │ seller_zip      │
                          │ order_id (FK)  │       │ seller_city     │
                          │ review_score   │       │ seller_state    │
                          │ creation_date  │       └─────────────────┘
                          └────────────────┘
```

### Table Summaries

| Table | Records | Description |
|-------|---------|-------------|
| `customers` | 95,000 | Unique customer profiles with location data |
| `orders` | 99,500 | Order information with timestamps |
| `order_items` | 139,253 | Item details with pricing and seller |
| `payments` | 99,500 | Payment method and installment information |
| `reviews` | 67,562 | Customer satisfaction scores and feedback |
| `products` | 32,000 | Product catalog with category and attributes |
| `sellers` | 3,200 | Seller profiles with geographic distribution |
| `geolocation` | 318 | ZIP code to latitude/longitude |

---

## Executive Summary

### Overview of Findings

The Olist marketplace grew steadily from late 2016 through mid-2018; year-over-year revenue increases averaged 68% when comparing January-August periods. Key performance indicators show healthy e-commerce operation with R$21.5 million in delivered order revenue from 60,596 unique customers. Around 80% of customers gave 4 or 5 stars, which indicators solid overall satisfaction.

The analysis reveals three main areas of focus. First, the Southeast region accounts for 58% of revenue, with Sao Paulo alone at 34%. Secondly, the top 3 product categories make up 38% of revenue, which leaves opportunities for category diversification beyond these top performers. Thirdly, delivery performance seems consistent across regions, but remote areas may still have room for improvement.

### Key Performance Indicators (2016-2018)

| Metric | Value | YoY Change |
|--------|-------|------------|
| Total Delivered Orders | 96,518 | +68% |
| Total Revenue | R$21.46M | +70% |
| Average Order Value | R$222 | -2% |
| Unique Customers | 60,596 | +65% |
| Average Review Score | 4.26 / 5.00 | Stable |
| Order Cancellation Rate | 1.43% | Stable |

Below is the executive overview dashboard from the analysis.

![Executive Dashboard](/visualizations/04_executive_dashboard.png)

---

## Insights Deep Dive

### 1. Sales Trends & Seasonality

Revenue grew sharply from 2017 to 2018, with clear seasonal peaks that could guide inventory and marketing decisions.

- **Peak Performance:** November 2017 had the highest monthly revenue at R$1.54M, roughly 72% above the monthly average. Black Friday promotions likely drove this increase.

- **Year-over-Year Growth:** Comparing Jan-Aug 2018 vs. 2017, every month showed positive growth ranging from +56% in August to +88% in January. The platform's customer base expanded significantly during this period.

- **Seasonal Patterns:** 
  - **High Season:** November (+72% vs. average), May (+20% for Mother's Day), December (+15%)
  - **Low Season:** January and February dip after the holidays (-20% vs. average)
  - **Weekly Pattern:** Weekday orders average 25% higher than weekends

- **Strategic implication:** Promotional calendars tied to Brazilian holidays (Black Friday, Mother's Day, Children's Day in October) could take advantage of these seasonal bumps more effectively.

![Sales Trends](/visualizations/05_sales_trends.png)

### 2. Regional Performance

The Southeast region dominates the marketplace, which reflects Brazil's economic concentration. Still, other regions may offer untapped potential.

- **Market Concentration:** Sao Paulo alone brings in 34.2% of revenue (R$7.6M), followed by Rio de Janeiro (11.5%), then Minas Gerais (9.6%). Together, these three states account for 55% of total revenue.

- **Regional Distribution:**
  | Region | Revenue Share | Avg Freight | Avg Delivery Days |
  |--------|--------------|-------------|-------------------|
  | Southeast | 58% | R$23.65 | 12.5 |
  | South | 19% | R$23.69 | 12.6 |
  | Northeast | 12% | R$23.78 | 12.5 |
  | Central-West | 8% | R$23.79 | 12.6 |
  | North | 3% | R$23.53 | 12.6 |

- **Logistics insight:** Freight costs stay relatively consistent across regions (R$23.50 to R$24.00), which suggests logistics partnerships and operations are efficient. However, delivery times show less variation than would be expected given the distances of travel, which could indicate standardized shipping regardless of distance.

- **Growth opportunity:** North and Northeast regions are underrepresented given their population. Targeted marketing campaigns and seller recruitment there could open new growth.

![Regional Analysis](/visualizations/06_regional_analysis.png)

### 3. Product Category Performance

The product portfolio shows good diversification, though the top categories contribute disproportionately to revenue. Spreading sales across more categories could reduce risk, improve product mix, and even grow basket sizes.

- **Top 3 Categories by Revenue:**
  1. Furniture & Decor: R$3.54M (16%) - Highest revenue but also highest freight costs
  2. Bed Bath Table: R$2.57M (11.6%) - Strong volume contribution with 23,704 items sold
  3. Computers & Accessories: R$2.38M (10.7%) - High-value items with R$195 average price

- **Price Tier Analysis:**
  - Premium (more than R$200 avg): Furniture Decor, Electronics
  - Mid-Range (R$100-200): Sports Leisure, Computers
  - Value (less than R$100): Stationery, Housewares, Toys

- **Category concentration risk:** Top 3 categories represent 39% of revenue. Diversification into underperforming categories (Fashion, Stationery) could reduce risk and increase basket size.

- **Customer ratings by category:** All categories score healthy, consistent ratings betwen 4.21 and 4.29. Telephony (4.29) and Toys (4.28) lead slightly; Perfumery is next in ranking at 4.21, which shows slight underperformance and might need a review of product quality or handling.

![Product Categories](/visualizations/07_product_categories.png)

### 4. Customer Analysis & Behavior

The customer base is growing but shows typical e-commerce patterns with most buyers purchasing only one. Repeat customers, though fewer, generate a disproportionate share of revenue.

- **Purchase Frequency:**
  | Segment | Customers | % of Base | Total Revenue | Avg LTV |
  |---------|-----------|-----------|---------------|---------|
  | One-time (1 order) | 34,953 | 57.7% | R$7.8M | R$223 |
  | Repeat (2 orders) | 17,691 | 29.2% | R$7.9M | R$444 |
  | Loyal (3+ orders) | 7,952 | 13.1% | R$5.8M | R$730 |

- **Customer value insight:** Repeat customers represent 42% of the base but generate 64% of revenue. A customer with 3+ orders has a lifetime value 3.3 times higher than a one-time buyer, at R$730 vs. R$223.

- **Acquisition trends:** New customer acquisition peaked during Black Friday, as November 2017 saw 4,166 new customers, and showed consistent month-over-month growth averaging added 8% through to 2018.

- **Retention opportunity:** Implementing loyalty programs, personalized recommendations, and re-engagement campaigns could convert more one-time buyers to repeat customers, which would likely increase revenue.

### 5. Payment Method Breakdown

Credit card method dominates, and installment plans are common for more expensive items.

- **Payment Method Distribution:**
  | Method | Transactions | Share | Avg Value |
  |--------|-------------|-------|-----------|
  | Credit Card | 71,269 | 74% | R$223 |
  | Boleto | 18,456 | 19% | R$221 |
  | Voucher | 3,860 | 4% | R$219 |
  | Debit Card | 2,933 | 3% | R$226 |

- **Installment Usage with Credit Card:**
  - 35% pay in full (1 installment)
  - 40% use 2-4 installments
  - 25% use 5-12 installments
  - Average: 3.4 installments

- **Business Insight:** Two thirds of credit card buyers split payments, which suggests price sensitivity. Offering 0% interest installment promotions could push conversion, particularly for higher-value categories like Electronics and Furniture.

### 6. Customer Satisfaction & Reviews

Customer satisfaction is strong overall, and delivery performance, surprisingly, has less impact on ratings than expected.

- **Review Score Distribution:**
  - 5 stars: 65% of reviews
  - 4 stars: 15%
  - 3 stars: 8%
  - 2 stars: 4%
  - 1 star: 8%

- **Satisfaction rate:** 80% of reviews are 4 stars or higher, indicating healthy overall satisfaction.

- **Impact of delivery:** On-time/early deliveries and late deliveries similar satisfaction rates of around 80%. This could suggest that delivery timing has less impact than expected. This could suggest that estimated delivery windows are conservatively set, which could be why they are so similar across regions.

- **Category satisfaction:** Telephony (which has a satisfaction score of 4.29) and Toys (with a score of 4.28) lead in customer satisfaction, while Perfumery (4.21) slightly underperforms. All categories remain above 4.0.

---

## Recommendations

Based on the analysis, the following are some strategic recommendations:

### For Marketing & Growth Teams

1. **Invest more into Black Friday:** November generates 72% above-average revenue. Consider week-long "Black November" campaign instead of a singular day of "Black Friday" and stock up on top product categories two months in advance.

2. **Target underserved regions:** Launch targeted campaigns in the North and Northeast regions, which represent only 15% of revenue despite having 35% of Brazil's population. Regional influencer partnerships and free shipping offers could help.

3. **Build around Mother's Day:** May shows good seasonal performance. Create dedicated Mother's Day gift bundles in Health & Beauty, Watches, and Bed Bath Table with 6-10 installment options, as this could capture more of this seasonal demand.

### For Product & Category Optimization

4. **Diversify beyond top 3:** The top 3 categories (Furniture, Bed Bath Table, and Computers) represent 38% of revenue. Invest in underperforming categories like Fashion and Stationery to spread risk:
   - Fashion Bags & Accessories: Currently only 1.9% of revenue despite high margins.
   - Stationery: Low price point is a good opportunity for cross-selling tactics.
   
5. **Push electronics:** Highest average price (R$238) and strong ratingsmake this category a candidate for expanded selection and electronic brand partnerships.

6. **Review Perfumery quality:** Lowest satisfaction score (4.21) may signal issues with product quality, seller performance, or shipping for fragile items.

### For Customer Retention

7. **Launch a loyalty program:** 42% of customers make repeat purchases, generating 64% of revenue. Initiating a tiered loyalty program could move more one-time buyers into this group. This program could include features like:
   - 5% discount after 2nd purchase
   - Free shipping after 3rd purchase
   - Early access to promotions for 5+ orders

8. **Win-Back Campaigns:** Target the 58% of one-time customers with personalized emails 90 days after purchase is made, featuring products relating to their purchase. This could re-engage them.

### For Operations & Logistics

9. **Recruit sellers outside Sao Paulo:** 55% of sellers are based in Sao Paulo. Adding sellers in the South and Northeast would cut shipping times and costs for customers in those regions.

10. **Consider regional freight pricing:** Flat, uniform rates could be holding back growth in the North and Northeast regions. Competitive pricing could build market share.

---

## Limitations and Future Work:

**Current Limitations:**
- The dataset only covers from September 2016 to August 2018, and does not provide data into more recent trends.
- 2016 data starts in September and 2018 data ends in August, so full year-over-year comparisons are not possible for all months.
- There is no product cost data provided, so profit margins cannot be calculated in detail.

**Future Enhancements:**
- Create seller performance scoring based on delivery time and ratings.
- Forecast future sales with time series modeling.
- Delve into product relation/affinity analysis to find opportunities for cross-selling.
- Include delivery route optimization analysis using geographical data.

---

## Technical Implementation

### SQL Queries Reference

The analysis was conducted using SQLite with the following query categories:

| Query Type | Purpose | Key Functions |
|------------|---------|---------------|
| Key Metrics | Orders, revenue, AOV, satisfaction | `COUNT(DISTINCT)`, `SUM()`, `AVG()`, multi-table joins |
| Sales Trends | Monthly revenue, peak month, day of week | `strftime()` date functions, window functions |
| Regional Performance | Revenue by state, regional breakdown | `CASE WHEN` for region mapping, percentage calculations |
| Product Categories | Top categories, category satisfaction | `GROUP BY` category, `HAVING` filters |
| Customer Segments | Purchase frequency, repeat buyer revenue | CTEs, customer aggregation, `CASE WHEN` segmentation |
| Payment Methods | Payment breakdown, installment usage | `GROUP BY` payment type, conditional grouping |
| Customer Satisfaction | Review distribution, delivery impact | Score distribution, date comparisons |
| Seller Analysis | Sellers by state | `COUNT(DISTINCT)`, percentage of total |

### Repository Structure

```
├── README.md                      
├── sql/
│   ├── 02_data_inspection.sql    
│   └── 03_analysis_queries.sql     
└── visualizations/
    ├── 04_executive_dashboard.png
    ├── 05_sales_trends.png
    ├── 06_regional_analysis.png
    └── 07_product_categories.png
```

### Data Source

This analysis uses the [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), available on Kaggle.
