require 'rails_helper'

RSpec.describe CandidateMailer, type: :mailer do
  include CourseOptionHelpers
  include TestHelpers::MailerSetupHelper

  subject(:mailer) { described_class }

  shared_examples 'a mail with subject and content' do |mail, subject, content|
    let(:email) { described_class.send(mail, @application_form) }

    it 'sends an email with the correct subject' do
      expect(email.subject).to include(subject)
    end

    content.each do |key, expectation|
      it "sends an email containing the #{key} in the body" do
        expectation = expectation.call if expectation.respond_to?(:call)
        expect(email.body).to include(expectation)
      end
    end
  end

  before do
    setup_application
    magic_link_stubbing(@candidate)
  end

  describe '.application_submitted' do
    let(:mail) { mailer.application_submitted(@application_form) }

    it_behaves_like(
      'a mail with subject and content',
      :application_submitted,
      I18n.t!('candidate_mailer.application_submitted.subject'),
      'heading' => 'Application submitted',
      'support reference' => 'SUPPORT-REFERENCE',
      'magic link to authenticate' => 'http://localhost:3000/candidate/confirm_authentication?token=raw_token&u=encrypted_id',
    )
  end

  describe 'Send survey email' do
    context 'when initial email' do
      it_behaves_like('a mail with subject and content', :survey_email,
                      'Was applying for teacher training easy?',
                      'heading' => 'Dear Bob',
                      'link to the survey' => I18n.t!('survey_emails.survey_link'))
    end

    context 'when chaser email' do
      it_behaves_like('a mail with subject and content', :survey_chaser_email,
                      'We’d love to hear from you about your teacher training application',
                      'heading' => 'Dear Bob',
                      'link to the survey' => I18n.t!('survey_emails.survey_link'))
    end
  end

  describe 'Candidate decision chaser email' do
    context 'when a candidate has one appication choice with offer' do
      it_behaves_like(
        'a mail with subject and content', :chase_candidate_decision,
        I18n.t!('chase_candidate_decision_email.subject_singular'),
        'heading' => 'Dear Bob',
        'days left to respond' => -> { "#{TimeLimitCalculator.new(rule: :chase_candidate_before_dbd, effective_date: Time.zone.today).call.fetch(:days)} working days" },
        'dbd date' => -> { 10.business_days.from_now.to_s(:govuk_date).strip },
        'course name and code' => 'Applied Science (Psychology)',
        'provider name' => 'Brighthurst Technical College'
      )
    end

    context 'when a candidate has multiple application choices with offer' do
      before do
        setup_application_form_with_two_offers(@application_form)
      end

      it_behaves_like(
        'a mail with subject and content', :chase_candidate_decision,
        I18n.t!('chase_candidate_decision_email.subject_plural'),
        'first course with offer' => 'MS Painting',
        'first course provider with offer' => 'Wen University',
        'second course with offer' => 'Code Refactoring',
        'second course provider with offer' => 'Ting University'
      )
    end
  end

  describe '.decline_by_default' do
    context 'when a candidate has 1 offer that was declined' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :declined_by_default,
        'You did not respond to your offer: next steps',
        'heading' => 'Dear Fred',
        'days left to respond' => '10 working days',
      )
    end

    context 'when a candidate has 2 or 3 offers that were declined' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
          ],
        )
      end

      it_behaves_like 'a mail with subject and content', :declined_by_default, 'You did not respond to your offers: next steps', {}
    end

    context 'when a candidate has 1 offer that was declined by default and a rejection' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'rejected'),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :declined_by_default,
        'You did not respond to your offer: next steps',
        'heading' => 'Dear Fred',
        'DBD_days_they_had_to_respond' => '10 working days',
        'still_interested' => 'If now’s the right time for you',
      )
    end

    context 'when a candidate has 2 offers that were declined by default and a rejection' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'rejected'),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :declined_by_default,
        'You did not respond to your offers: next steps',
        'heading' => 'Dear Fred',
        'DBD_days_they_had_to_respond' => '10 working days',
        'still_interested' => 'If now’s the right time for you',
      )
    end

    context 'when a candidate has 1 offer that was declined and it awaiting another decision' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'awaiting_provider_decision'),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :declined_by_default,
        'Application withdrawn automatically',
        'heading' => 'Dear Fred',
        'days left to respond' => '10 working days',
      )
    end

    context 'when a candidate has 2 offers that was declined and it awaiting another decision' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'declined', declined_by_default: true, decline_by_default_days: 10),
            build_stubbed(:application_choice, status: 'awaiting_provider_decision'),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :declined_by_default,
        'Applications withdrawn automatically',
        'heading' => 'Dear Fred',
        'days left to respond' => '10 working days',
      )
    end
  end

  describe '.withdraw_last_application_choice' do
    context 'when a candidate has 1 course choice that was withdrawn' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'withdrawn'),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :withdraw_last_application_choice,
        'You’ve withdrawn your application: next steps',
        'heading' => 'Dear Fred',
        'application_withdrawn' => 'You’ve withdrawn your application',
      )
    end

    context 'when a candidate has 2 or 3 offers that were declined' do
      before do
        @application_form = build_stubbed(
          :application_form,
          first_name: 'Fred',
          candidate: @candidate,
          application_choices: [
            build_stubbed(:application_choice, status: 'withdrawn'),
            build_stubbed(:application_choice, status: 'withdrawn'),
          ],
        )
      end

      it_behaves_like(
        'a mail with subject and content',
        :withdraw_last_application_choice,
        'You’ve withdrawn your applications: next steps',
        'application_withdrawn' => 'You’ve withdrawn your application',
      )
    end
  end

  describe '.decline_last_application_choice' do
    let(:email) { described_class.decline_last_application_choice(@application_form.application_choices.first) }

    before do
      @application_form = build_stubbed(
        :application_form,
        first_name: 'Fred',
        candidate: @candidate,
        application_choices: [
          build_stubbed(:application_choice, status: 'declined'),
        ],
      )
    end

    it 'has the right subject and content' do
      expect(email.subject).to eq 'You’ve declined an offer: next steps'
      expect(email).to have_content 'Dear Fred'
      expect(email).to have_content 'declined your offer to study'
    end
  end

  describe '#apply_again_call_to_action' do
    it 'has the correct subject and content' do
      application_form = build_stubbed(
        :application_form,
        first_name: 'Fred',
        candidate: @candidate,
        application_choices: [
          build_stubbed(
            :application_choice,
            status: 'rejected',
            course_option: build_stubbed(
              :course_option,
              course: build_stubbed(
                :course,
                name: 'Mathematics',
                code: 'M101',
                provider: build_stubbed(
                  :provider,
                  name: 'Cholbury College',
                ),
              ),
            ),
          ),
        ],
      )
      email = described_class.apply_again_call_to_action(application_form)

      expect(email.subject).to eq 'You can still apply for teacher training'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include('You can apply for teacher training again if you have not got a place yet')
    end
  end

  describe '.chase_reference_again' do
    let(:email) { described_class.chase_reference_again(@referee) }

    before do
      @referee = build_stubbed(:reference, application_form: @application_form)
    end

    it 'has the right subject and content' do
      expect(email.subject).to eq "#{@referee.name} has not responded yet"
    end
  end

  describe '#application_rejected_all_rejected' do
    def build_stubbed_application_form(rejected_by_default: false, rejection_reason: nil)
      build_stubbed(
        :application_form,
        first_name: 'Fred',
        candidate: @candidate,
        application_choices: [
          build_stubbed(
            :application_choice,
            status: 'rejected',
            rejected_by_default: rejected_by_default,
            rejection_reason: rejection_reason,
            course_option: build_stubbed(
              :course_option,
              site: build_stubbed(
                :site,
                name: 'West Wilford School',
              ),
              course: build_stubbed(
                :course,
                name: 'Mathematics',
                code: 'M101',
                provider: build_stubbed(
                  :provider,
                  name: 'Bilberry College',
                ),
              ),
            ),
          ),
        ],
      )
    end

    def send_email(rejected_by_default: false, rejection_reason: nil)
      application_form = build_stubbed_application_form(
        rejected_by_default: rejected_by_default,
        rejection_reason: rejection_reason,
      )
      application_choice = application_form.application_choices.first
      described_class.application_rejected_all_rejected(application_choice)
    end

    it 'has the correct subject and content' do
      email = send_email

      expect(email.subject).to eq 'Your application was unsuccessful but you can apply again'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include(
        'Bilberry College has decided not to progress your teacher training application for Mathematics (M101) on this occasion.',
      )
      expect(email.body).to include('Apply again:')
      expect(email.body).not_to include('Review your feedback and apply again:')
    end

    it 'has the correct subject and content for rejection by default' do
      email = send_email(rejected_by_default: true)

      expect(email.subject).to eq 'Your application was unsuccessful but you can apply again'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include(
        'Bilberry College did not respond to your application for Mathematics (M101) in time.',
      )
    end

    it 'has the correct content when rejection reason is given' do
      email = send_email(rejected_by_default: true, rejection_reason: 'Not clever enough')

      expect(email.body).not_to include('Apply again:')
      expect(email.body).to include('Review your feedback and apply again:')
    end
  end

  describe '#application_rejected_awaiting_decisions' do
    def build_stubbed_application_form(rejected_by_default: false)
      build_stubbed(
        :application_form,
        first_name: 'Fred',
        candidate: @candidate,
        application_choices: [
          build_stubbed(
            :application_choice,
            status: 'rejected',
            rejected_by_default: rejected_by_default,
            course_option: build_stubbed(
              :course_option,
              site: build_stubbed(
                :site,
                name: 'West Wilford School',
              ),
              course: build_stubbed(
                :course,
                name: 'Mathematics',
                code: 'M101',
                provider: build_stubbed(
                  :provider,
                  name: 'Bilberry College',
                ),
              ),
            ),
          ),
          build_stubbed(
            :application_choice,
            status: 'awaiting_provider_decision',
            course_option: build_stubbed(
              :course_option,
              site: build_stubbed(
                :site,
                name: 'East Wilford School',
              ),
              course: build_stubbed(
                :course,
                name: 'Physics',
                code: 'P101',
                provider: build_stubbed(
                  :provider,
                  name: 'Bulberry College',
                ),
              ),
            ),
          ),
        ],
      )
    end

    def send_email(rejected_by_default: false)
      application_form = build_stubbed_application_form(rejected_by_default: rejected_by_default)
      application_choice = application_form.application_choices.first
      described_class.application_rejected_awaiting_decisions(application_choice)
    end

    it 'has the correct subject and content' do
      email = send_email

      expect(email.subject).to eq 'Bilberry College has made a decision on your application for Mathematics (M101)'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include(
        'Bilberry College has decided not to progress your teacher training application for Mathematics (M101) on this occasion.',
      )
      expect(email.body).to include('Decisions we’re waiting for')
    end

    it 'has the correct subject and content for rejection by default' do
      email = send_email(rejected_by_default: true)

      expect(email.subject).to eq 'Your application was unsuccessful but you can apply again'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include(
        'Your application for Mathematics (M101) has been automatically rejected because Bilberry College did not respond in time.',
      )
      expect(email.body).not_to include('Decisions we’re waiting for')
    end
  end

  describe '#application_rejected_offers_made' do
    def build_stubbed_application_form(rejected_by_default: false)
      build_stubbed(
        :application_form,
        first_name: 'Fred',
        candidate: @candidate,
        application_choices: [
          build_stubbed(
            :application_choice,
            status: 'rejected',
            rejected_by_default: rejected_by_default,
            course_option: build_stubbed(
              :course_option,
              site: build_stubbed(
                :site,
                name: 'West Wilford School',
              ),
              course: build_stubbed(
                :course,
                name: 'Mathematics',
                code: 'M101',
                provider: build_stubbed(
                  :provider,
                  name: 'Bilberry College',
                ),
              ),
            ),
          ),
          build_stubbed(
            :application_choice,
            status: 'offer',
            decline_by_default_at: 10.days.from_now,
            decline_by_default_days: 10,
            course_option: build_stubbed(
              :course_option,
              site: build_stubbed(
                :site,
                name: 'East Wilford School',
              ),
              course: build_stubbed(
                :course,
                name: 'Physics',
                code: 'P101',
                provider: build_stubbed(
                  :provider,
                  name: 'Bulberry College',
                ),
              ),
            ),
          ),
        ],
      )
    end

    def send_email(rejected_by_default: false)
      application_form = build_stubbed_application_form(rejected_by_default: rejected_by_default)
      application_choice = application_form.application_choices.first
      described_class.application_rejected_offers_made(application_choice)
    end

    it 'has the correct subject and content' do
      email = send_email

      expect(email.subject).to eq 'Bilberry College has responded: make a decision within 10 working days'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include(
        'Bilberry College has decided not to progress your teacher training application for Mathematics (M101) on this occasion.',
      )
    end

    it 'has the correct subject and content for rejection by default' do
      email = send_email(rejected_by_default: true)

      expect(email.subject).to eq 'Your application was unsuccessful but you can apply again'
      expect(email.body).to include('Dear Fred,')
      expect(email.body).to include(
        'Your application for Mathematics (M101) has been automatically rejected because Bilberry College did not respond in time.',
      )
    end
  end

  describe '#offer_accepted' do
    def build_stubbed_application_form
      build_stubbed(
        :application_form,
        first_name: 'Bob',
        candidate: @candidate,
        application_choices: [
          build_stubbed(
            :application_choice,
            status: 'pending_conditions',
            course_option: build_stubbed(
              :course_option,
              site: build_stubbed(
                :site,
                name: 'West Wilford School',
              ),
              course: build_stubbed(
                :course,
                name: 'Mathematics',
                code: 'M101',
                start_date: Time.zone.local(2021, 9, 6),
                provider: build_stubbed(
                  :provider,
                  name: 'Arithmetic College',
                ),
              ),
            ),
          ),
        ],
      )
    end

    def send_email
      application_form = build_stubbed_application_form
      application_choice = application_form.application_choices.first
      described_class.offer_accepted(application_choice)
    end

    it 'has the correct subject and content' do
      email = send_email

      expect(email.subject).to eq(
        'You’ve accepted Arithmetic College’s offer to study Mathematics (M101)',
      )
      expect(email.body).to include('Dear Bob,')
      expect(email.body).to include(
        'You’ve accepted Arithmetic College’s offer to study Mathematics (M101)',
      )
    end
  end
end
