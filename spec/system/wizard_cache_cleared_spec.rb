require 'rails_helper'

RSpec.describe 'Clearing the wizard cache' do
  include CourseOptionHelpers
  include DfESignInHelpers
  include ProviderUserPermissionsHelper

  let(:application_choice) { create(:application_choice, :awaiting_provider_decision, course_option: course_option) }
  let(:course_option) { course_option_for_provider_code(provider_code: 'ABC') }

  around do |example|
    Timecop.freeze(Time.zone.now) do
      example.run
    end
  end

  # check InterviewsController for configuration
  scenario 'when the user re-enters a wizard the cache is cleared' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_i_am_permitted_to_set_up_interviews_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_visit_that_application_in_the_provider_interface
    and_i_click_set_up_an_interview
    and_i_fill_out_the_interview_form(days_in_future: 1, time: '12pm')

    and_i_go_back
    and_i_go_back_again
    then_i_should_be_on_the_application_page

    when_i_click_set_up_an_interview
    then_i_should_see_an_empty_interview_form
  end

  # check ReasonsForRejectionController for configuration
  scenario 'on entrypoint checks, when the user re-enters a wizard from a specified entrypoint the cache is cleared' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_i_am_permitted_to_make_decisions_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_visit_that_application_in_the_provider_interface
    and_i_click_make_decision

    when_i_choose_to_reject_application
    and_i_select_why_i_am_rejecting_the_application
    and_i_go_back
    and_i_go_back_again
    then_i_should_be_on_the_decision_page

    when_i_choose_to_reject_application
    then_i_should_see_a_cleared_reasons_for_rejection_page
  end

  def given_i_am_a_provider_user_with_dfe_sign_in
    provider_exists_in_dfe_sign_in
  end

  def and_i_am_permitted_to_set_up_interviews_for_my_provider
    provider_user_exists_in_apply_database
    permit_set_up_interviews!
  end

  def and_i_am_permitted_to_make_decisions_for_my_provider
    provider_user_exists_in_apply_database
    permit_make_decisions!
  end

  def when_i_visit_that_application_in_the_provider_interface
    visit provider_interface_application_choice_path(application_choice)
  end

  def and_i_click_set_up_an_interview
    click_on 'Set up interview'
  end

  def and_i_click_make_decision
    click_on 'Make decision'
  end

  def when_i_choose_to_reject_application
    choose 'Reject application'
    click_on 'Continue'
  end

  alias_method :when_i_click_set_up_an_interview, :and_i_click_set_up_an_interview

  def and_i_fill_out_the_interview_form(days_in_future:, time:)
    tomorrow = days_in_future.day.from_now
    fill_in 'Day', with: tomorrow.day
    fill_in 'Month', with: tomorrow.month
    fill_in 'Year', with: tomorrow.year

    fill_in 'Time', with: time

    fill_in 'Address or online meeting details', with: 'N/A'

    click_on 'Continue'
  end

  def and_i_go_back
    click_on 'Back'
  end

  alias_method :and_i_go_back_again, :and_i_go_back

  def then_i_should_be_on_the_application_page
    expect(page).to have_current_path(provider_interface_application_choice_path(application_choice))
  end

  def then_i_should_see_an_empty_interview_form
    expect(page).to have_content('Set up an interview')

    expect(page.find_field('Day').value).to be_nil
    expect(page.find_field('Month').value).to be_nil
    expect(page.find_field('Year').value).to be_nil
    expect(page.find_field('Time').value).to be_nil
    expect(page.find_field('Address or online meeting details').value).to be_empty
  end

  def then_i_should_be_on_the_decision_page
    expect(page).to have_current_path(new_provider_interface_application_choice_decision_path(application_choice))
  end

  def and_i_select_why_i_am_rejecting_the_application
    choose 'reasons-for-rejection-candidate-behaviour-y-n-no-field'

    choose 'reasons-for-rejection-quality-of-application-y-n-no-field'

    choose 'reasons-for-rejection-qualifications-y-n-yes-field'
    check 'reasons-for-rejection-qualifications-which-qualifications-no-maths-gcse-field'
    check 'reasons-for-rejection-qualifications-which-qualifications-no-degree-field'

    choose 'reasons-for-rejection-performance-at-interview-y-n-no-field'

    choose 'reasons-for-rejection-course-full-y-n-no-field'

    choose 'reasons-for-rejection-offered-on-another-course-y-n-no-field'

    choose 'reasons-for-rejection-honesty-and-professionalism-y-n-yes-field'
    check 'reasons-for-rejection-honesty-and-professionalism-concerns-information-false-or-inaccurate-field'
    fill_in 'reasons-for-rejection-honesty-and-professionalism-concerns-information-false-or-inaccurate-details-field', with: 'We doubt claims about your golf handicap'
    check 'reasons-for-rejection-honesty-and-professionalism-concerns-references-field'
    fill_in 'reasons-for-rejection-honesty-and-professionalism-concerns-references-details-field', with: 'We cannot accept references from your mum'

    choose 'reasons-for-rejection-safeguarding-y-n-yes-field'
    check 'reasons-for-rejection-safeguarding-concerns-vetting-disclosed-information-field'
    fill_in 'reasons-for-rejection-safeguarding-concerns-vetting-disclosed-information-details-field', with: 'You abducted Jenny, now Matrix is coming to find her'

    choose 'reasons-for-rejection-cannot-sponsor-visa-y-n-no-field'

    click_on t('continue')
  end

  def then_i_should_see_a_cleared_reasons_for_rejection_page
    click_on t('continue')

    within '.govuk-error-summary' do
      expect(page).to have_content('There is a problem')
      expect(page).to have_css('.govuk-error-summary__list li', count: 9)
    end
  end
end