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
```sql

---

### Explanation of the Sections:

1. **Product & Inventory Analysis:**
   - This section focuses on product performance, inventory classification, and availability across stores.
   - Insights give an overview of the analysis, like identifying overstock and understock issues and tracking sales trends.

2. **Sales Trend Analysis:**
   - This section describes how sales are tracked over time, comparing monthly and YoY trends, as well as analyzing specific product categories.
   - Key insights focus on identifying seasonal trends, growth rates, and tracking category performance.

3. **Operational Metrics:**
   - This analysis involves order fulfillment, tracking staff sales performance, and benchmarking store performance.
   - Insights include average processing times, top-performing staff, and store comparison metrics.

4. **Sample Findings:**
   - These findings are a quick summary of key insights related to customer behavior, inventory, sales trends, and staff performance, with specific data points like revenue concentration, inventory optimization needs, sales peak trends, and staff performance metrics.

---

This structured format will ensure that your `README.md` file looks clear, professional, and easy to read for anyone exploring your project.


