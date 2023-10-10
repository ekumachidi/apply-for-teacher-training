require 'rails_helper'

RSpec.describe 'Course is not available' do
  subject(:application_choice_submission) do
    CandidateInterface::ContinuousApplications::ApplicationChoiceSubmission.new(application_choice:)
  end

  let(:application_form) { create(:application_form) }
  let(:application_choice) { create(:application_choice, application_form:) }

  context 'sections incomplete' do
    let(:application_form) { create(:application_form, :minimum_info, degrees_completed: false) }
    let(:application_choice) { create(:application_choice, application_form:) }

    it 'adds error to application choice' do
      view = ActionView::Base.new(ActionView::LookupContext::DetailsKey.view_context_class(ActionView::Base), {}, ApplicationController.new)
      travel_temporarily_to(mid_cycle) do
        expect(application_choice_submission).not_to be_valid
        binding.pry
        expect(application_choice_submission.errors[:application_choice]).to include(
          <<~MSG,
            You cannot submit this application as the course is no longer available.

            #{view.govuk_link_to('Remove this application', Rails.application.routes.url_helpers.candidate_interface_continuous_applications_confirm_destroy_course_choice_path(application_choice.id))} and search for other courses.
          MSG
        )
      end
    end
  end
end
