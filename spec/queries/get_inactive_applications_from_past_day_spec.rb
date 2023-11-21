require 'rails_helper'

RSpec.describe GetInactiveApplicationsFromPastDay do
  before do
    create_list(:application_choice, 3)
  end

  describe '#call' do
    it 'returns an empty set if no inactive applications are found' do
      expect(described_class.call).to be_empty
    end

    context 'when there are inactive applications' do
      let(:application_form) { create(:application_form) }
      let!(:application_choice) { create(:application_choice, :inactive) }
      let!(:application_choices) { create_list(:application_choice, 2, :inactive, application_form:) }

      context 'when single is true' do
        it 'returns applications that have one inactive choice' do
          expect(described_class.call(single: true).pluck(:id)).to eq([application_choice.application_form_id])
        end
      end

      context 'when single is false' do
        it 'returns applications that have multiple inactive choices' do
          expect(described_class.call(single: false).pluck(:id)).to eq([application_choices.first.application_form_id])
        end
      end
    end
  end
end
