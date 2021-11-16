require 'rails_helper'

RSpec.describe MonthlyStatisticsTimetable do
  describe '#generate_monthly_statistics' do
    it 'returns true if the monthly report is scheduled to run on the current date' do
      MonthlyStatisticsTimetable::GENERATION_DATES.each_value do |date|
        Timecop.travel(date) do
          expect(described_class.generate_monthly_statistics?).to eq true
        end
      end
    end

    it 'returns false if the monthly report is not scheduled to run on the current date' do
      MonthlyStatisticsTimetable::GENERATION_DATES.each_value do |date|
        date = [date - 1.day, date + 1.day].sample

        Timecop.travel(date) do
          expect(described_class.generate_monthly_statistics?).to eq false
        end
      end
    end
  end

  describe '#latest_report_date' do
    context 'when the most recent generation date is within the same month' do
      it 'returns the correct value' do
        Timecop.travel(described_class::GENERATION_DATES.values.first + 1.day) do
          expect(described_class.latest_report_date).to eq described_class::GENERATION_DATES.values.first
        end
      end
    end

    context 'when the most recent generation date was last month' do
      it 'returns the correct value' do
        Timecop.travel(described_class::GENERATION_DATES.values.second - 1.day) do
          expect(described_class.latest_report_date).to eq described_class::GENERATION_DATES.values.first
        end
      end
    end
  end
end
