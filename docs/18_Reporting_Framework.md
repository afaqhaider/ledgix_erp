# 18 Reporting Framework

## Categories

### 1. Financial Reports (Real-time)
- **Trial Balance:** List of all accounts and their current balances.
- **Profit & Loss (Income Statement):** Revenue vs Expenses over a period.
- **Balance Sheet:** Snapshot of Assets, Liabilities, and Equity.
- **Cash Flow Statement:** Inflow and outflow of cash.

### 2. Operational Reports
- **AR/AP Aging:** Summary of unpaid invoices/bills by time period (30, 60, 90+ days).
- **Inventory Valuation:** Current stock value based on FIFO, LIFO, or Average Cost.
- **Sales by Customer/Product:** Performance tracking.

### 3. Management Dashboard (KPIs)
- **Current Ratio:** Liquidity check.
- **Gross Margin:** Profitability per product/service.
- **Burn Rate:** Monthly expense tracking for startups/SMEs.
- **Top 5 Customers:** Concentration risk analysis.

## Export Formats
- **PDF:** For official distribution and printing.
- **Excel/CSV:** For data analysis and external auditing.
- **JSON:** For integration with BI tools.

## Technical Implementation
- Client-side aggregation for small datasets.
- Cloud Functions for heavy aggregation and historical snapshots.
- Future: Dedicated reporting database (BigQuery/PostgreSQL) for large-scale analytics.
