require 'rails_helper'

RSpec.describe 'CandidateInterface ApplicationChoice index' do
  include CandidateHelper

  scenario 'Application rejected with rejection_reasons is visible' do
    given_i_am_signed_in
    and_i_have_a_rejected_application

    when_i_visit_the_application_choices_page
    then_i_see_my_application_shows_the_application_rejection_reason
    and_i_see_the_rejection_feedback_form
  end

  def given_i_am_signed_in
    login_as(@candidate = create(:candidate))
  end

  def and_i_have_a_rejected_application
    @choice = create(:application_choice, :rejected_reasons, application_form: create(:application_form, candidate: @candidate))
  end

  def when_i_visit_the_application_choices_page
    visit candidate_interface_continuous_applications_choices_path
  end

  def then_i_see_my_application_shows_the_application_rejection_reason
    within("[data-qa='application-choice-#{@choice.id}']") do
      expect(page.text).to include('Feedback')

      expect(page.text).to include('Qualifications',
                                   'We could find no record of your GCSEs.',
                                   'Personal statement',
                                   'We do not accept applications written in Old Norse.',
                                   'References',
                                   'We do not accept references from close family members, such as your mum.')
    end
  end

  def and_i_see_the_rejection_feedback_form
    within("[data-qa='application-choice-#{@choice.id}']") do
      expect(page.text).to include('Is this feedback helpful?',
                                   'Yes',
                                   'No')
    end
  end
end
