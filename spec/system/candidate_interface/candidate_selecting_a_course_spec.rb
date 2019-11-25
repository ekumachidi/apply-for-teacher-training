require 'rails_helper'

RSpec.feature 'Selecting a course' do
  include CandidateHelper

  scenario 'Candidate selects a course choice' do
    given_i_am_signed_in
    and_data_from_find_exists

    when_i_visit_the_site
    and_i_click_on_course_choices
    and_i_click_on_add_course
    and_i_choose_that_i_know_where_i_want_to_apply
    and_i_choose_a_provider
    and_i_choose_a_course
    and_i_choose_a_location
    then_i_see_my_completed_course_choice

    # attempt to add the same course
    when_i_click_on_add_another_course
    and_i_choose_that_i_know_where_i_want_to_apply
    and_i_choose_a_provider
    and_i_choose_a_course
    then_i_see_a_message_that_ive_already_chosen_the_course

    when_i_mark_this_section_as_completed
    when_i_click_continue
    then_i_see_that_the_section_is_completed

    and_i_click_on_course_choices
    and_i_delete_my_course_choice
    and_i_confirm_that_i_want_to_delete_my_choice
    then_i_no_longer_see_my_course_choice
  end

  def given_i_am_signed_in
    create_and_sign_in_candidate
  end

  def and_data_from_find_exists
    provider = create(:provider, name: 'Gorse SCITT', code: '1N1')
    site = create(:site, name: 'Main site', code: '-', provider: provider)
    course = create(:course, name: 'Primary', code: '2XT2', provider: provider, exposed_in_find: true, open_on_apply: true)
    create(:course_option, site: site, course: course, vacancy_status: 'B')
  end

  def when_i_visit_the_site
    visit candidate_interface_application_form_path
  end

  def and_i_click_on_course_choices
    click_link 'Course choices'
  end

  def and_i_click_on_add_course
    click_link 'Continue'
  end

  def and_i_choose_that_i_know_where_i_want_to_apply
    choose 'Yes, I know where I want to apply'
    click_button 'Continue'
  end

  def and_i_choose_a_provider
    choose 'Gorse SCITT (1N1)'
    click_button 'Continue'
  end

  def and_i_choose_a_course
    choose 'Primary (2XT2)'
    click_button 'Continue'
  end

  def and_i_choose_a_location
    choose 'Main site'
    click_button 'Continue'
  end

  def then_i_see_my_completed_course_choice
    expect(page).to have_content('Gorse SCITT')
    expect(page).to have_content('Primary (2XT2)')
    expect(page).to have_content('Main site')
  end

  def when_i_click_on_add_another_course
    click_link 'Add another course'
  end

  def then_i_see_a_message_that_ive_already_chosen_the_course
    expect(page).to have_css('.govuk-error-summary', text: 'You have already selected this course')
  end

  def when_i_mark_this_section_as_completed
    visit candidate_interface_course_choices_index_path
    check t('application_form.courses.complete.completed_checkbox')
  end

  def then_i_see_that_the_section_is_completed
    expect(page).to have_css('#course-choices-badge-id', text: 'Completed')
  end

  def when_i_click_continue
    click_button 'Continue'
  end

  def and_i_delete_my_course_choice
    click_link t('application_form.courses.delete')
  end

  def and_i_confirm_that_i_want_to_delete_my_choice
    click_button t('application_form.courses.confirm_delete')
  end

  def then_i_no_longer_see_my_course_choice
    expect(page).not_to have_content('Primary (2XT2)')
  end
end
