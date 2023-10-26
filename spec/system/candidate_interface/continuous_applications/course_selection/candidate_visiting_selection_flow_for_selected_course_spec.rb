require 'rails_helper'

RSpec.feature 'Selecting a course', :continuous_applications do
  include CandidateHelper

  it 'Candidate selects a course they have already applied to when editing' do
    given_i_am_signed_in
    and_is_one_course_option_with_both_study_modes_and_two_sites
    and_i_have_an_unsubmitted_applicaiton_to_the_course

    when_i_visit_the_site
    and_i_visit_the_study_mode_selection_for_my_existing_course_selection
    then_i_am_redirected_to_the_duplicate_course_selection_step

    when_i_visit_the_sites_selection_for_my_existing_course_selection
    then_i_am_redirected_to_the_duplicate_course_selection_step

    when_i_click_the_back_link
    then_i_am_on_the_which_course_step
  end

  def given_i_am_signed_in
    @candidate = create(:candidate)
    create_and_sign_in_candidate(candidate: @candidate)
  end

  def and_is_one_course_option_with_both_study_modes_and_two_sites
    provider = create(:provider, name: 'Gorse SCITT', code: '1N1')

    site = create(:site, provider:)
    create(:site, provider:)
    @course_one = create(:course, :open_on_apply, :with_both_study_modes, name: 'Primary', code: '2XT2', provider:)
    create(:course_option, site:, course: @course_one, study_mode: :full_time)
    create(:course_option, site:, course: @course_one, study_mode: :part_time)
  end

  def and_i_have_an_unsubmitted_applicaiton_to_the_course
    @application_one = create(:application_choice, :unsubmitted, course_option: @course_one.course_options.first, application_form: @candidate.current_application)
  end

  def when_i_visit_the_site
    visit candidate_interface_application_form_path
  end

  def and_i_visit_the_study_mode_selection_for_my_existing_course_selection
    visit candidate_interface_continuous_applications_course_study_mode_path(provider_id: @course_one.provider_id, course_id: @course_one.id)
  end

  def when_i_visit_the_sites_selection_for_my_existing_course_selection
    visit candidate_interface_continuous_applications_course_site_path(provider_id: @course_one.provider_id, course_id: @course_one.id, study_mode: :full_time)
  end

  def then_i_am_redirected_to_the_duplicate_course_selection_step
    expect(page).to have_current_path(candidate_interface_continuous_applications_duplicate_course_selection_path(@course_one.provider.id, @course_one.id))
  end

  def when_i_click_the_back_link
    click_link 'Back'
  end

  def then_i_am_on_the_which_course_step
    expect(page).to have_current_path(candidate_interface_continuous_applications_which_course_are_you_applying_to_path(@course_one.provider.id))
  end
end
