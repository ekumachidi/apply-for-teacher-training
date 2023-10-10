require 'rails_helper'

RSpec.describe 'Incomplete form details', time: CycleTimetableHelper.mid_cycle do
  subject(:application_choice_submission) do
    CandidateInterface::ContinuousApplications::ApplicationChoiceSubmission.new(application_choice:)
  end

  context 'missing details'
  context 'valid, then add primary choice, invalid, add science GCSE, valid'

  let(:view) { ActionView::Base.new(ActionView::LookupContext::DetailsKey.view_context_class(ActionView::Base), {}, ApplicationController.new) }
  let(:application_form) { create(:application_form, :completed) }
  let(:application_choice) { create(:application_choice, application_form:) }

  context 'valid' do
    it 'is valid' do
      expect(application_choice_submission).to be_valid
    end
  end

  context 'sections incomplete' do
    let(:application_form) { create(:application_form, :minimum_info) }
    let(:application_choice) { create(:application_choice, application_form:) }

    it 'adds error to application choice' do
      expect(application_choice_submission).not_to be_valid
      expect(application_choice_submission.errors[:application_choice]).to include(message)
    end
  end

  context 'when science gcse is required' do
    let(:course_option) { build(:course_option, course:) }
    let(:course) { create(:course, :open_on_apply, :primary) }
    let(:application_form) { create(:application_form, :minimum_info) }
    let(:application_choice) { create(:application_choice, course_option: course_option, application_form:) }

    it 'adds error to application choice' do
      expect(application_choice_submission).not_to be_valid
      expect(application_choice_submission.errors[:application_choice]).to include(message)
    end
  end

  def message
    <<~MSG
      You cannot submit this application until you #{view.govuk_link_to('complete your details', Rails.application.routes.url_helpers.candidate_interface_continuous_applications_details_path)}.

      Your application will be saved as a draft while you finish adding your details.
    MSG
  end
end
