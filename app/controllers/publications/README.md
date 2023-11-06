# Generate Monthly Stats locally

    dashboard = Publications::MonthlyStatistics::MonthlyStatisticsReport.new_report
    dashboard.load_table_data
    dashboard.save!


Visit `http://localhost:3000/publications/monthly-statistics/ITT2023`
