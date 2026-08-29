# ✈️ US Airline Operational Performance & Delay Analytics

An end-to-end Business Intelligence project analyzing flight punctuality, delay root causes, airport congestion bottlenecks, and in-flight delay recovery dynamics across major US carriers.

<img width="1998" height="1598" alt="image" src="https://github.com/user-attachments/assets/78ebb48c-1598-4455-8615-431cc525801f" />


---

## 🔗 Live Interactive Dashboard
👉 **[View Interactive Dashboard on Tableau Public](https://public.tableau.com/views/USAirlineOperationalPerformanceDelayAnalytics/USAirlineOperationalPerformanceDelayAnalytics?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**

---

## 📊 Analytical Focus & Key Insights

1. **Airline On-Time Performance (OTP) Benchmarking:**
   - Evaluates industry punctuality against the 80% DOT benchmark.
   - Highlights high-performing carriers (HA, AS) versus bottom-tier performers (MQ, B6).

2. **Delay Root-Cause Breakdown:**
   - Quantifies the impact of Late Aircraft (~38%) and Carrier Operations (~31%) as primary delay drivers over localized weather disruptions.

3. **Airport Taxi-Out Congestion Analysis:**
   - Geospatial mapping of origin hub taxi durations to identify ground operational bottlenecks (e.g., LGA, BOS, ORD, PHL).

4. **In-Flight Delay Recovery Performance:**
   - Measures airborne recovery efficiency, showing how carriers (UA, WN, DL) recover schedule time during the flight phase versus regional short-haul limitations.

5. **Hourly Flight Volume vs. Delay Accumulation:**
   - Dual-axis trend analysis tracking how early morning schedule buffers deteriorate into late-day delay cascades.

---

## 🛠️ Tech Stack & Methodology

* **Data Engineering / SQL (DBeaver / PostgreSQL):** Aggregations, window functions, conditional recovery logic, and KPI calculations.
* **Data Visualization (Tableau Public):** Dual-axis charts, custom bins, layout containers, geospatial mapping, and customized tooltips.

---

## 📁 Repository Structure

* `airline_delay_queries.sql`: Complete SQL pipeline and data transformations for all 5 analyses.
* `airline_delay_dashboard.twbx`: Packaged Tableau workbook containing all sheets, containers, and dashboard layouts.
* `dashboard_preview.png`: Full executive dashboard preview for direct visual inspection.
* `1_otp_benchmarking.csv` - Punctuality metrics and 80% OTP threshold evaluation data.
* `2_delay_root_cause.csv` - Carrier, Late Aircraft, NAS, Weather, and Security delay breakdown.
* `3_taxi_out_congestion.csv` - Hub airport taxi-out durations and departure delay metrics.
* `4_in_flight_recovery.csv` - Airborne delay reduction efficiency per airline.
* `5_hourly_delay_accumulation.csv` - Departure hour traffic volume vs. average delay progression.

---

* ## 💾 Data Source & Preprocessing
- **Source:** US Bureau of Transportation Statistics (BTS) / Kaggle Flight Delay Dataset (~200MB+ raw records).
- **Processing:** Raw operational records were cleaned and standardized via SQL views (`view_clean_flights`), filtering invalid records, null cancellations, and computing recovery metrics.
- **Datasets:** Aggregated analytical datasets used for visualization are stored in the root directory (`1_otp_benchmarking.csv` to `5_hourly_delay_accumulation.csv`).
