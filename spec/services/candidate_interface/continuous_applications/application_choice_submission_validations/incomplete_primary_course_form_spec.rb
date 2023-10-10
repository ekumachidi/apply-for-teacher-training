require 'rails_helper'

RSpec.describe 'Incomplete primary course form details', time: CycleTimetableHelper.mid_cycle do
  subject(:application_choice_submission) do
    CandidateInterface::ContinuousApplications::ApplicationChoiceSubmission.new(application_choice:)
  end

  context 'missing details'
  context 'valid, then add primary choice, invalid, add science GCSE, valid'

  let(:view) { ActionView::Base.new(ActionView::LookupContext::DetailsKey.view_context_class(ActionView::Base), {}, ApplicationController.new) }
  let(:course_option) { build(:course_option, course:) }
  let(:course) { create(:course, :open_on_apply) }
  let(:application_form) { create(:application_form, :completed) }
  let(:application_choice) { create(:application_choice, application_form:, course_option:) }

  context 'valid' do
    it 'is valid' do
      expect(application_choice_submission).to be_valid
    end
  end

  context 'science gcse section incomplete' do
    let(:course_option) { build(:course_option, course:) }
    let(:course) { create(:course, :open_on_apply) }
    let(:application_form) { create(:application_form, :minimum_info, science_gcse_completed: false) }
    let(:application_choice) { create(:application_choice, course_option:, application_form:) }

    it 'adds error to application choice' do
      expect(application_choice_submission).not_to be_valid
      expect(application_choice_submission.errors[:application_choice]).to include(message)
    end
  end

  def message
    <<~MSG
      To apply for a Primary course, you need a GCSE in science at grade 4 (C) or above, or equivalent.

      Add your science GCSE grade (or equivalent). You can then submit this application.

      Your application will be saved as a draft while you finish adding your details.
    MSG
  end
end
