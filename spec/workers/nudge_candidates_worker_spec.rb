require 'rails_helper'

RSpec.describe NudgeCandidatesWorker, :sidekiq do
  describe '#perform' do
    let(:application_form_unstarted) { create(:application_form) }
    let(:application_form) { create(:completed_application_form) }
    let(:application_form_with_no_courses) { create(:application_form) }
    let(:application_form_with_no_personal_statement) { create(:application_form) }

    before do
      query = instance_double(
        GetUnsubmittedApplicationsReadyToNudge,
        call: [application_form],
      )
      second_query = instance_double(
        GetIncompleteCourseChoiceApplicationsReadyToNudge,
        call: [application_form_with_no_courses],
      )
      third_query = instance_double(
        GetIncompletePersonalStatementApplicationsReadyToNudge,
        call: [application_form_with_no_personal_statement],
      )
      query_for_unstarted = instance_double(
        GetUnstartedApplicationsReadyToNudge,
        call: [application_form_unstarted],
      )

      allow(GetUnsubmittedApplicationsReadyToNudge).to receive(:new).and_return(query)
      allow(GetUnstartedApplicationsReadyToNudge).to receive(:new).and_return(query_for_unstarted)
      allow(GetIncompleteCourseChoiceApplicationsReadyToNudge).to receive(:new).and_return(second_query)
      allow(GetIncompletePersonalStatementApplicationsReadyToNudge).to receive(:new).and_return(third_query)
    end

    it 'sends email to candidates with an unstarted application' do
      described_class.new.perform

      email = email_for_candidate(application_form_unstarted.candidate)

      expect(email).to be_present
      expect(email.subject).to include('Start your teacher training application')
    end

    it 'sends email to candidates with an unsubmitted completed application' do
      described_class.new.perform

      email = email_for_candidate(application_form.candidate)

      expect(email).to be_present
      expect(email.subject).to include('Get last-minute advice about your teacher training application')
    end

    it 'sends email to candidates with zero course choices on their application' do
      described_class.new.perform

      email = email_for_candidate(application_form_with_no_courses.candidate)

      expect(email).to be_present
      expect(email.subject).to include(
        I18n.t!('candidate_mailer.nudge_unsubmitted_with_incomplete_courses.subject'),
      )
    end

    it 'sends email to candidates with incomplete personal statement on their application' do
      described_class.new.perform

      email = email_for_candidate(application_form_with_no_personal_statement.candidate)

      expect(email).to be_present
      expect(email.subject).to include(
        I18n.t!('candidate_mailer.nudge_unsubmitted_with_incomplete_personal_statement.subject'),
      )
    end
  end

  def email_for_candidate(candidate)
    ActionMailer::Base.deliveries.find { |email| email.header['to'].value == candidate.email_address }
  end
end
