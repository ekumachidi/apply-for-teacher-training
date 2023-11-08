require 'rails_helper'

RSpec.describe Publications::ITTMonthlyReportGenerator do
  describe '#generation_date' do
    context 'when passing in initialize' do
      it 'returns custom generation date' do
        generation_date = 1.week.ago
        expect(described_class.new(generation_date:).generation_date).to eq(generation_date)
      end
    end

    context 'when not passing in initialize' do
      it 'returns current date' do
        generation_date = Time.zone.now

        travel_temporarily_to(generation_date, freeze: true) do
          expect(described_class.new.generation_date).to eq(generation_date)
        end
      end
    end
  end

  describe '#first_cycle_week' do
    context 'when we are on 2023 recruitment cycle' do
      it 'returns first monday week of beginning of the cycle' do
        travel_temporarily_to(Time.zone.local(2023, 9, 1)) do
          expect(described_class.new.first_cycle_week).to eq(Time.zone.local(2022, 10, 3))
        end
      end
    end

    context 'when we are on 2024 recruitment cycle' do
      it 'returns first monday week of beginning of the cycle' do
        travel_temporarily_to(Time.zone.local(2023, 11, 15)) do
          expect(described_class.new.first_cycle_week).to eq(Time.zone.local(2023, 10, 2))
        end
      end
    end
  end

  describe '#report_expected_time' do
    it 'returns the last Sunday of the expected generation time' do
      generation_date = Time.zone.local(2023, 11, 8)
      expect(described_class.new(generation_date:).report_expected_time).to eq(Time.zone.local(2023, 11, 5))
    end
  end

  describe '#cycle_week' do
    context 'when first cycle week' do
      it 'returns one' do
        generation_date = Time.zone.local(2023, 10, 9)
        expect(described_class.new(generation_date:).cycle_week).to be 1
      end
    end

    context 'when mid cycle' do
      it 'returns the number of weeks' do
        generation_date = Time.zone.local(2023, 11, 20)
        expect(described_class.new(generation_date:).cycle_week).to be 7
      end
    end

    context 'when last cycle week' do
      it 'returns 52' do
        generation_date = Time.zone.local(2024, 9, 30)
        expect(described_class.new(generation_date:).cycle_week).to be 52
      end
    end
  end

  describe '#to_h' do
    subject(:report) do
      described_class.new(generation_date:).to_h
    end

    let(:generation_date) { Time.zone.local(2023, 11, 22) }
    let(:candidate_headline_statistics) do
      {
        cycle_week: 7,
        first_date_in_week: Date.new(2023, 11, 13),
        last_date_in_week: Date.new(2023, 11, 19),
        number_of_candidates_accepted_to_date: 538,
        number_of_candidates_accepted_to_same_date_previous_cycle: 478,
        number_of_candidates_submitted_to_date: 8586,
        number_of_candidates_submitted_to_same_date_previous_cycle: 5160,
        number_of_candidates_who_did_not_meet_any_offer_conditions_this_cycle_to_date: 0,
        number_of_candidates_who_did_not_meet_any_offer_conditions_this_cycle_to_same_date_previous_cycle: 0,
        number_of_candidates_who_had_all_applications_rejected_this_cycle_to_date: 246,
        number_of_candidates_who_had_all_applications_rejected_this_cycle_to_same_date_previous_cycle: 131,
        number_of_candidates_with_all_accepted_offers_withdrawn_this_cycle_to_date: 1,
        number_of_candidates_with_all_accepted_offers_withdrawn_this_cycle_to_same_date_previous_cycle: 0,
        number_of_candidates_with_deferred_offers_from_this_cycle_to_date: 0,
        number_of_candidates_with_deferred_offers_from_this_cycle_to_same_date_previous_cycle: 0,
        number_of_candidates_with_offers_to_date: 598,
        number_of_candidates_with_offers_to_same_date_previous_cycle: 567,
        number_of_candidates_with_reconfirmed_offers_deferred_from_previous_cycle_to_date: 285,
        number_of_candidates_with_reconfirmed_offers_deferred_from_previous_cycle_to_same_date_previous_cycle: 213,
      }
    end

    before do
      allow(DfE::Bigquery::ApplicationMetrics).to receive(:candidate_headline_statistics)
        .with(cycle_week: 7)
        .and_return(DfE::Bigquery::ApplicationMetrics.new(candidate_headline_statistics))
    end

    it 'returns meta information' do
      expect(report[:meta]).to eq({
        generation_date:,
        period: 'From 2 October 2023 to 19 November 2023',
        cycle_week: 7,
      })
    end

    it 'returns candidate headline statistics' do
      expect(report[:candidate_headline_statistics]).to eq({
        title: 'Candidate Headline statistics',
        data: {
          submitted: {
            title: 'Submitted',
            this_cycle: 8586,
            last_cycle: 5160,
          },
          with_offers: {
            title: 'With offers',
            this_cycle: 598,
            last_cycle: 567,
          },
          accepted: {
            title: 'Accepted',
            this_cycle: 538,
            last_cycle: 478,
          },
          rejected: {
            title: 'All applications rejected',
            this_cycle: 246,
            last_cycle: 131,
          },
          reconfirmed: {
            title: 'Reconfirmed from previous cycle',
            this_cycle: 285,
            last_cycle: 213,
          },
          deferred: {
            title: 'Deferred',
            this_cycle: 0,
            last_cycle: 0,
          },
          withdrawn: {
            title: 'Withdrawn',
            this_cycle: 1,
            last_cycle: 0,
          },
          conditions_not_met: {
            title: 'Offer conditions not met',
            this_cycle: 0,
            last_cycle: 0,
          },
        },
      })
    end
  end
end
