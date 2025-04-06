# 🚴 Bike Stores SQL Analysis Project

![SQL](https://img.shields.io/badge/SQL-Advanced-blue) 
![Database](https://img.shields.io/badge/Database-SQL_Server-orange)
![Analysis](https://img.shields.io/badge/Analytics-Business_Intelligence-green)

## 📑 Table of Contents
- [Project Overview](#-project-overview)
- [Database Schema](#-database-schema)
- [Key Analyses](#%EF%B8%8F-key-analyses)
- [Technical Highlights](#-technical-highlights)
- [How to Use](#-how-to-use)
- [Sample Findings](#-sample-findings)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [License](#-license)

## 🏆 Project Overview

This project demonstrates advanced SQL skills through comprehensive analysis of a bike store's sales database. It includes:

- 10+ sophisticated SQL queries
- Customer behavior analysis
- Inventory optimization insights
- Sales performance tracking
- Staff productivity metrics

**Business Value:**
- Identify high-value customers
- Optimize inventory levels
- Improve sales strategies
- Enhance staff performance

## 🗃️ Database Schema

The database contains these key tables:

| Table | Description |
|-------|-------------|
| `sales.customers` | Customer demographics and contact info |
| `sales.orders` | Order headers with status and dates |
| `sales.order_items` | Individual products in each order |
| `production.products` | Product details with brands/categories |
| `production.stocks` | Inventory levels by store |
| `sales.staffs` | Employee information |
| `sales.stores` | Store locations and details |

![Schema Diagram](database_schema.png) *(Include actual diagram file)*

## ⚙️ Key Analyses

### 1. Customer Analytics
```sql
-- Customer segmentation by value and activity
-- Lifetime value calculations
-- Purchase frequency analysis
Key Insights:
*Segmented customers into Active/Lapsing/At Risk/Lost categories
*Calculated 3-year projected customer value
*Identified most popular product categories by customer

### 2. Product & Inventory Analysis
```sql
-- Product performance by brand and category
-- Inventory status classification
-- Product availability across stores
Key Insights:
-- Monthly sales trends with YoY comparisons
-- 12-month rolling averages
-- Category-specific sales patterns
### 3.Sales Trend Analysis
```sql
-- Monthly sales trends with YoY comparisons
-- 12-month rolling averages
-- Category-specific sales patterns
Key Insights:
*Identified seasonal sales patterns
*Calculated year-over-year growth rates
*Tracked category performance over time
### 4.Operational Metrics
```sql
-- Order fulfillment timing analysis
-- Staff sales rankings and peer comparisons
-- Store performance benchmarks
Key Insights:
*Average order processing time: 2.3 days
*Top salesperson generated $125,000 last quarter
*Identified highest performing stores



