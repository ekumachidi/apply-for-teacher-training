FactoryBot.define do
  factory :monthly_statistics_report, class: '::Publications::MonthlyStatistics::MonthlyStatisticsReport' do
    month { '2023-12' }
    generation_date { Time.zone.local(2023, 12, 18) }
    publication_date { Time.zone.local(2023, 12, 25) }
    statistics { DfE::Bigquery::StubbedReport.new }

    trait :v1 do
      statistics { V1MonthlyStatisticsStubbedReport.new.to_h }
    end
  end
end
