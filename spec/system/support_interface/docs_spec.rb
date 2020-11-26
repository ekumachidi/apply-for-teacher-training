require 'rails_helper'

RSpec.feature 'Docs' do
  include DfESignInHelpers

  scenario 'Support user visits process documentation' do
    given_i_am_a_support_user
    when_i_visit_the_process_documentation
    then_i_see_the_provider_flow_documentation
    and_it_contains_documentation_for_all_emails

    when_i_click_on_candidate_flow_documentation
    then_i_see_the_candidate_flow_documentation
  end

  def given_i_am_a_support_user
    sign_in_as_support_user
  end

  def when_i_visit_the_process_documentation
    visit support_interface_docs_provider_flow_path
  end

  def then_i_see_the_provider_flow_documentation
    expect(page).to have_title 'Provider application flow'
  end

  def and_it_contains_documentation_for_all_emails
    emails_outside_of_states = %w[
      provider_mailer-account_created
      provider_mailer-fallback_sign_in_email
      provider_mailer-ucas_match_initial_email_duplicate_applications
      candidate_mailer-apply_again_call_to_action
      candidate_mailer-course_unavailable_notification
      candidate_mailer-ucas_match_initial_email_duplicate_applications
      candidate_mailer-ucas_match_initial_email_multiple_acceptances
      candidate_mailer-ucas_match_reminder_email_duplicate_applications
    ]

    # extract all the emails that we send into a list of strings like "referee_mailer-reference_request_chaser_email"
    emails_sent = [CandidateMailer, ProviderMailer, RefereeMailer].flat_map { |k| k.public_instance_methods(false).map { |m| "#{k.name.underscore}-#{m}" } }
    documented_application_choice_emails = I18n.t('events').flat_map { |_name, attrs| attrs[:emails] }.compact.uniq
    documented_chaser_emails = I18n.t('application_states').flat_map { |_name, attrs| attrs[:emails] }.compact.uniq

    emails_documented = documented_application_choice_emails + documented_chaser_emails + emails_outside_of_states

    # TODO: remove this once application_withrawn is completely gone
    emails_documented -= %w[provider_mailer-application_withrawn]
    emails_sent -= %w[provider_mailer-application_withrawn]

    expect(emails_documented).to match_array(emails_sent)
  end

  def when_i_click_on_candidate_flow_documentation
    click_on 'Candidate flow'
  end

  def then_i_see_the_candidate_flow_documentation
    expect(page).to have_title 'Candidate application flow'
  end
end
