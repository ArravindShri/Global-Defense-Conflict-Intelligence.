# Global Defense & Conflict Intelligence Dashboard

End-to-end defense analytics platform analyzing 25+ years of global arms trade, military spending, and political violence data across 187 countries — built with SQL Server (Medallion Architecture) and Tableau.

[▶ View Live Dashboard]https://public.tableau.com/app/profile/arravindshri.shri/viz/GlobalDefenceConflictIntelligenceAnalysis/GlobalTradeOverview**

## Why This Project

In 2016, India signed the Rafale jet deal — a $8.7 billion agreement that sparked national debate about defense spending transparency. As an Indian citizen, I wanted to answer a simple question: *where does the money actually go?* This dashboard connects arms trade flows, military budgets, conflict patterns, and social spending tradeoffs to give any informed citizen the tools to investigate defense policy decisions through data. I wanted to do this for a very long time. But needed to do properly too. I still feel like it can be done better :) 

## Tech Stack

| Layer | Tool |
|-------|------|
| Database | SQL Server 2017 |
| Architecture | Medallion (Bronze → Silver → Gold) |
| ETL | Python (World Bank API), SQL Server Import Wizard |
| Visualization | Tableau Public |
| Version Control | Git + GitHub |

## Data Sources

| Source | Description | Records |
|--------|------------|---------|
| SIPRI Arms Transfers | Individual arms trade deals (1998–2024) | ~34,000 |
| SIPRI Military Expenditure | 3 metrics × 187 countries × 24 years | ~13,000 |
| SIPRI Top 100 Companies | Global defense company rankings | 100 |
| ACLED Conflict Events | Political violence across 6 regions | ~85,000 |
| World Bank API | GDP, education, healthcare, debt, population | ~28,000 |

## Architecture

| Layer | Tables | Purpose |
|-------|--------|---------|
| Bronze | 7 | Raw data ingestion — no transformation |
| Silver | 9 | Cleaned, standardized, country-mapped (4 reference + 5 data) |
| Gold | 8 | Business-ready aggregations powering Tableau |

## Key Findings

- **India's import dependency** is concentrated across Russia (83 deals), France, and Israel — with a visible shift away from Russian suppliers post-2014.
- **United States dominates exports** to 40+ countries, with South Korea, Saudi Arabia, and Australia as top recipients.
- **Budget crowding is highest in Singapore and Pakistan** — countries where military spending as a share of government budget far exceeds social sector investment.
- **Pearson correlation of 0.86** between conflict events and military spending in India — as violence increases, defense budgets follow.
- **Russia → India is the strongest bilateral defense partnership** globally with 83 deals across 21 active years.

## Key Technical Features

- **Trade flow line maps** using SQL view (UNION to reshape source/target coordinates) with Tableau Line + Path marks
- **Cross-data-source filtering** using Tableau Parameters instead of standard filters
- **Political era overlay** — arms deals mapped to government leadership periods across 10 countries
- **Pearson correlation in pure SQL** — no Python or R, calculated using the statistical formula directly
- **Budget Crowding Index** — custom metric: military share of govt spending ÷ average social sector spending
- **Wide-to-long UNPIVOT** on 3 SIPRI datasets (24 year columns → normalized rows)
- **World Bank API pagination** — Python script handles multi-page responses across 6 indicators
