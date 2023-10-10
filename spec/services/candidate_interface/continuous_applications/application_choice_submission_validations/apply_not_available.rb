require 'rails_helper'

RSpec.describe 'Applications not open' do
  subject(:application_choice_submission) do
    CandidateInterface::ContinuousApplications::ApplicationChoiceSubmission.new(application_choice:)
  end

  let(:application_form) { create(:application_form) }
  let(:application_choice) { create(:application_choice, application_form:) }

  # when apply closed
  # when apply open but course closed
  # when apply open and course open
  context 'when candidate can not apply outside of the cycle' do
    it 'adds error to application choice' do
      travel_temporarily_to(Time.zone.local(2023, 10, 4)) do
        expect(application_choice_submission).not_to be_valid
        expect(application_choice_submission.errors[:application_choice]).to include(
          'This course is not yet open to applications. You’ll be able to submit your application on 4 August 2023.',
        )
      end
    end
  end

  context 'when apply id open but course not open for applications' do
    it 'adds error to application choice' do
      travel_temporarily_to(mid_cycle) do
        application_choice.course.update(applications_open_from: 1.day.from_now)

        expect(application_choice_submission).not_to be_valid
        expect(application_choice_submission.errors[:application_choice]).to include(
          "This course is not yet open to applications. You’ll be able to submit your application on #{1.day.from_now.to_fs(:govuk_date)}.",
        )
      end
    end
  end
end
