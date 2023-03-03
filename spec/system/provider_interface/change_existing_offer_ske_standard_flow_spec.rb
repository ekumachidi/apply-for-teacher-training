require 'rails_helper'

RSpec.feature 'Provider changes an existing offer' do
  include DfESignInHelpers
  include ProviderUserPermissionsHelper
  include OfferStepsHelper

  let(:provider_user) { create(:provider_user, :with_dfe_sign_in) }
  let(:provider) { provider_user.providers.first }
  let(:ratifying_provider) { create(:provider) }
  let(:application_form) { build(:application_form, :minimum_info) }
  let(:conditions) do
    [build(:offer_condition, text: 'Fitness to train to teach check'),
     build(:offer_condition, text: 'Be cool')]
  end
  let!(:application_choice) do
    create(:application_choice,
           :offered,
           offer: build(:offer, conditions:),
           application_form:,
           current_course_option: course_option)
  end
  let(:course) do
    build(:course, :full_time, provider:, accredited_provider: ratifying_provider)
  end
  let(:course_option) { build(:course_option, course:) }

  scenario 'Changing an offer which has already been made' do
    given_i_am_a_provider_user
    and_i_am_permitted_to_make_decisions_for_my_provider
    and_i_sign_in_to_the_provider_interface
    and_provider_ske_feature_flag_is_enabled

    given_the_provider_user_can_offer_multiple_provider_courses

    when_i_visit_the_provider_interface
    and_i_click_an_application_choice_with_an_offer
    and_i_click_on_the_offer_tab
    then_i_see_the_offer_details

    # Change provider and course to a subject that permits SKE conditions
    when_i_choose_to_change_the_provider
    then_i_am_taken_to_the_change_provider_page

    when_i_select_a_different_provider
    and_i_click_continue

    when_i_select_a_different_course
    and_i_click_continue
    then_no_study_mode_is_pre_selected

    when_i_select_a_study_mode
    and_i_click_continue

    when_i_select_a_new_location
    and_i_click_continue
    then_the_ske_standard_flow_is_loaded

    when_i_select_ske_is_required
    and_i_click_continue
    then_the_ske_reason_page_is_loaded

    when_i_add_a_ske_reason
    and_i_click_continue
    then_the_ske_length_page_is_loaded

    when_i_answer_the_ske_length
    and_i_click_continue
    then_the_conditions_page_is_loaded
    and_the_conditions_of_the_original_offer_are_filled_in

    when_i_add_a_further_condition
    and_i_add_another_and_then_remove_a_further_condition
    then_the_correct_conditions_are_displayed

    and_i_click_continue

    then_the_review_page_is_loaded
    and_the_ske_conditions_should_be_displayed
    and_i_can_confirm_the_changed_offer_details

    when_i_send_the_offer
    then_i_see_that_the_offer_was_successfully_updated
    and_the_ske_conditions_should_be_displayed

    # Toggle the standard conditions and save
    when_i_choose_to_change_the_conditions
    and_i_click_continue
    then_the_review_page_is_loaded
    and_the_ske_conditions_should_be_displayed

    when_i_send_the_offer
    then_i_see_that_the_offer_was_successfully_updated
    and_i_can_see_the_new_offer_condition
    and_the_ske_conditions_should_be_displayed
  end

  def given_i_am_a_provider_user
    user_exists_in_dfe_sign_in(email_address: provider_user.email_address)
  end

  def and_i_am_permitted_to_make_decisions_for_my_provider
    permit_make_decisions!
  end

  def and_i_sign_in_to_the_provider_interface
    provider_signs_in_using_dfe_sign_in
  end

  def given_the_provider_user_can_offer_multiple_provider_courses
    @selected_provider = create(:provider)
    create(:provider_permissions, provider: @selected_provider, provider_user:, make_decisions: true)
    @ske_subject = create(:subject, code: 'C1', name: 'Biology')
    courses = create_list(:course, 2, subjects: [@ske_subject], study_mode: :full_time_or_part_time, provider: @selected_provider, accredited_provider: ratifying_provider)
    @selected_course = courses.sample

    course_options = [create(:course_option, :part_time, course: @selected_course),
                      create(:course_option, :full_time, course: @selected_course),
                      create(:course_option, :full_time, course: @selected_course),
                      create(:course_option, :part_time, course: @selected_course)]

    create(
      :provider_relationship_permissions,
      training_provider: provider,
      ratifying_provider:,
      ratifying_provider_can_make_decisions: true,
    )

    create(
      :provider_relationship_permissions,
      training_provider: @selected_provider,
      ratifying_provider:,
      ratifying_provider_can_make_decisions: true,
    )

    @selected_course_option = course_options.sample
  end

  def when_i_visit_the_provider_interface
    visit provider_interface_applications_path
  end

  def and_i_click_an_application_choice_with_an_offer
    click_on application_choice.application_form.full_name
  end

  def and_i_click_on_the_offer_tab
    click_on 'Offer'
  end

  def then_i_see_the_offer_details
    expect(page).to have_content('Course details')
    expect(page).to have_content('Conditions of offer')
  end

  def when_i_choose_to_change_the_provider
    within(all('.govuk-summary-list__row')[0]) do
      click_on 'Change'
    end
  end

  def then_i_am_taken_to_the_change_provider_page
    expect(page).to have_content('Training provider')
  end

  def when_i_select_a_different_provider
    choose @selected_provider.name_and_code
  end

  def and_i_click_continue
    click_on t('continue')
  end

  def when_i_select_a_different_course
    choose @selected_course.name_and_code
  end

  def then_no_study_mode_is_pre_selected
    expect(find_field('Full time')).not_to be_checked
    expect(find_field('Part time')).not_to be_checked
  end

  def when_i_select_a_study_mode
    choose @selected_course_option.study_mode.humanize
  end

  def when_i_select_a_new_location
    choose @selected_course_option.site_name
  end

  def then_the_ske_standard_flow_is_loaded
    expect(page).to have_current_path("/provider/applications/#{application_choice.id}/offer/ske-requirements/edit", ignore_query: true)
  end

  def when_i_select_ske_is_required
    choose 'Yes'
  end

  def then_the_ske_reason_page_is_loaded
    expect(page).to have_current_path("/provider/applications/#{application_choice.id}/offer/ske-reason/edit", ignore_query: true)
  end

  def when_i_add_a_ske_reason
    choose t('provider_interface.offer.ske_reasons.form.different_degree', degree_subject: @ske_subject.name)
  end

  def then_the_ske_length_page_is_loaded
    expect(page).to have_current_path("/provider/applications/#{application_choice.id}/offer/ske-length/edit", ignore_query: true)
  end

  def when_i_answer_the_ske_length
    choose '8 weeks'
  end

  def and_the_ske_conditions_should_be_displayed
    expect(page).to have_content('Subject knowledge enhancement course')
    expect(page).to have_content("Subject\n#{@ske_subject.name}")
    expect(page).to have_content("Length\n8 weeks")
    expect(page).to have_content("Reason\nTheir degree subject was not #{@ske_subject.name}")
  end

  def then_the_conditions_page_is_loaded
    expect(page).to have_content('Conditions of offer')
  end

  def and_the_conditions_of_the_original_offer_are_filled_in
    expect(find("input[value='Fitness to train to teach check']")).to be_checked
    expect(page).to have_field('Condition 1', with: 'Be cool')
  end

  def when_i_add_a_further_condition
    click_on 'Add another condition'
    fill_in('provider_interface_offer_wizard[further_conditions][1][text]', with: 'A* on Maths A Level')
  end

  def and_i_add_another_and_then_remove_a_further_condition
    click_on 'Add another condition'
    fill_in('provider_interface_offer_wizard[further_conditions][2][text]', with: 'Go to the cinema')
    click_on 'Remove condition 3'
  end

  def then_the_correct_conditions_are_displayed
    expect(page).to have_field('Condition 2', with: 'A* on Maths A Level')
    expect(page).not_to have_field('Condition 3', with: 'Go to the cinema')
  end

  def then_the_review_page_is_loaded
    expect(page).to have_content('Check and send new offer')
  end

  def and_i_can_confirm_the_changed_offer_details
    within('.app-offer-panel') do
      expect(page).to have_content(@selected_provider.name_and_code)
      expect(page).to have_content(@selected_course.name_and_code)
      expect(page).to have_content(@selected_course_option.study_mode.humanize)
      expect(page).to have_content(@selected_course_option.site.name_and_address(' '))
      expect(page).to have_content('Fitness to train to teach check')
      expect(page).to have_content('Be cool')
      expect(page).to have_content('A* on Maths A Level')
    end
  end

  def when_i_send_the_offer
    click_on 'Send new offer'
  end

  def and_i_can_see_the_new_offer_condition
    expect(page).not_to have_content('Fitness to train to teach check')
    expect(page).to have_content('Disclosure and Barring Service (DBS) check')
  end

  def then_i_see_that_the_offer_was_successfully_updated
    within('.govuk-notification-banner--success') do
      expect(page).to have_content('New offer sent')
    end
  end

  def when_i_choose_to_change_the_conditions
    click_on 'Add or change conditions'
    uncheck 'Fitness to train to teach check'
    check 'Disclosure and Barring Service (DBS) check'
  end
end
