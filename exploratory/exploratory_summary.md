# Exploratory Summary

These tables and charts summarize the final merged EV opportunity dataset produced in R.

## Score Summary

|State_Count |Average_Opportunity_Score |Median_Opportunity_Score |Minimum_Opportunity_Score |Maximum_Opportunity_Score |Average_EVs_Per_10000_Residents |Average_Chargers_Per_1000_EVs |Average_PlugShare_Per_10000_Residents |
|:-----------|:-------------------------|:------------------------|:-------------------------|:-------------------------|:-------------------------------|:-----------------------------|:-------------------------------------|
|50          |28.34                     |26.23                    |9.82                      |67.14                     |75.36                           |118.32                        |7.59                                  |

## Opportunity Category Summary

|Opportunity_Category |State_Count |Percent_of_States |
|:--------------------|:-----------|:-----------------|
|High                 |17          |34.0%             |
|Medium               |17          |34.0%             |
|Low                  |16          |32.0%             |

## Top 10 Opportunity States

|Rank |State         |Category |Score |EVs per 10,000 Residents |Chargers per 1,000 EVs |Economic Readiness |
|:----|:-------------|:--------|:-----|:------------------------|:----------------------|:------------------|
|1    |California    |High     |67.14 |319.30                   |59.58                  |82.11              |
|2    |Vermont       |High     |51.12 |121.40                   |186.92                 |40.71              |
|3    |Massachusetts |High     |45.64 |105.62                   |159.54                 |66.66              |
|4    |Washington    |High     |44.72 |197.83                   |60.65                  |61.85              |
|5    |Connecticut   |High     |42.80 |87.38                    |165.57                 |57.98              |
|6    |Colorado      |High     |42.39 |156.10                   |90.54                  |58.83              |
|7    |Wyoming       |High     |40.59 |19.71                    |309.04                 |38.73              |
|8    |Maryland      |High     |38.59 |117.08                   |83.75                  |69.44              |
|9    |Maine         |High     |38.03 |53.97                    |224.07                 |34.89              |
|10   |Hawaii        |High     |37.61 |176.24                   |43.65                  |61.69              |

## Bottom 10 Opportunity States

|Rank |State          |Category |Score |EVs per 10,000 Residents |Chargers per 1,000 EVs |Economic Readiness |
|:----|:--------------|:--------|:-----|:------------------------|:----------------------|:------------------|
|41   |Alabama        |Low      |19.12 |25.95                    |166.32                 |18.05              |
|42   |New Mexico     |Low      |18.80 |48.64                    |129.43                 |8.54               |
|43   |Tennessee      |Low      |18.54 |47.98                    |101.56                 |27.86              |
|44   |Indiana        |Low      |17.82 |38.47                    |95.17                  |34.70              |
|45   |South Carolina |Low      |17.61 |40.59                    |110.43                 |25.14              |
|46   |Arkansas       |Low      |17.20 |23.55                    |161.51                 |12.34              |
|47   |Mississippi    |Low      |17.05 |12.13                    |217.83                 |1.84               |
|48   |Oklahoma       |Low      |15.48 |57.53                    |83.44                  |20.02              |
|49   |Kentucky       |Low      |12.97 |25.80                    |108.55                 |17.15              |
|50   |Louisiana      |Low      |9.82  |17.56                    |118.04                 |8.79               |

## Metric Summary

|Metric                      |Min       |Median     |Mean       |Max         |
|:---------------------------|:---------|:----------|:----------|:-----------|
|AFDC_Charging_Station_Count |84.00     |756.00     |1697.92    |20578.00    |
|Chargers_Per_1000_EVs       |43.65     |99.29      |118.32     |309.04      |
|EV_Count                    |959.00    |25833.00   |70947.58   |1256646.00  |
|EV_Opportunity_Score        |9.82      |26.23      |28.34      |67.14       |
|EVs_Per_10000_Residents     |12.13     |55.77      |75.36      |319.30      |
|Median_Household_Income     |52985.00  |72090.00   |74266.70   |98461.00    |
|PlugShare_Station_Count     |323.00    |2867.00    |5270.14    |60319.00    |
|Population                  |577929.00 |4571740.50 |6608540.12 |39356104.00 |
|Poverty_Rate                |7.33      |11.85      |12.30      |19.20       |

## Charts

- `exploratory/charts/top_15_opportunity_states.png`
- `exploratory/charts/adoption_vs_charger_availability.png`
- `exploratory/charts/afdc_vs_plugshare_gap.png`
- `exploratory/charts/economic_readiness_context.png`
- `exploratory/charts/top_10_component_scores.png`
