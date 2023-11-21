require 'rails_helper'

RSpec.describe SendApplyToMultipleCoursesWhenInactiveEmailToCandidate do
  describe '#call' do
    let(:application_form) do
      create(
        :completed_application_form,
        application_choices: create_list(:application_choice, 2, :inactive),
      )
    end

    before do
      mail = instance_double(ActionMailer::MessageDelivery, deliver_later: true)
      allow(CandidateMailer).to receive(:apply_to_multiple_courses_after_30_working_days).and_return(mail)

      described_class.call(application_form)
    end

    it 'sends apply to multiple courses email' do
      expect(CandidateMailer).to have_received(
        :apply_to_multiple_courses_after_30_working_days,
      ).with(application_form)

      expect(application_form.chasers_sent.apply_to_multiple_courses_after_30_working_days.count).to eq(1)
    end

    it 'does not send the email again' do
      described_class.call(application_form)

      expect(CandidateMailer).to have_received(
        :apply_to_multiple_courses_after_30_working_days,
      ).with(application_form).once

      expect(application_form.chasers_sent.apply_to_multiple_courses_after_30_working_days.count).to eq(1)
    end
  end
end
