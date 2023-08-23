require 'rails_helper'

RSpec.describe CandidateInterface::ContinuousApplications::ApplicationSubmitComponent do
  subject(:result) do
    render_inline(described_class.new(application_choice:, form:))
  end

  let(:form) do
    GOVUKDesignSystemFormBuilder::FormBuilder.new(
      'submit_application_form',
      CandidateInterface::ContinuousApplications::SubmitApplicationForm.new,
      ActionView::Base.new(ActionView::LookupContext.new(nil), {}, ActionController::Base.new),
      {},
    )
  end

  context 'when application choice is submitted' do
    let(:application_choice) { create(:application_choice, :awaiting_provider_decision) }

    it 'does not render the component' do
      expect(result.text).to be_empty
    end
  end

  context 'when application is not submitted' do
    let(:application_choice) { create(:application_choice, :unsubmitted, application_form:) }

    context 'when your details are incomplete' do
      let(:application_form) { create(:application_form, :minimum_info) }

      it 'renders error message' do
        expect(result.text).to include(
          'You cannot submit this application until you’ve completed your details.',
        )
      end
    end

    context 'when candidate can not apply outside of the cycle' do
      let(:application_form) { create(:application_form, :completed) }

      it 'renders error message' do
        travel_temporarily_to(Time.zone.local(2023, 10, 4)) do
          expect(result.text).to include(
            'You cannot submit this application now. You will be able to submit it from 10 October 2023 at 9am.',
          )
        end
      end
    end

    context 'when course is not open for applications' do
      let(:course) do
        create(:course, :open_on_apply, name: 'Primary', code: '2XT2', applications_open_from: 2.days.from_now)
      end
      let(:course_option) { create(:course_option, course:) }
      let(:application_form) { create(:application_form, :completed) }
      let(:application_choice) do
        create(:application_choice, :unsubmitted, course_option:, application_form:)
      end

      it 'renders error message' do
        travel_temporarily_to(Time.zone.local(2023, 10, 11)) do
          expect(result.text).to include(
            "You cannot submit this application now because the course has not opened. You will be able to submit it from #{course.applications_open_from.to_fs(:govuk_date)}.",
          )
        end
      end
    end

    context 'when course is full' do
      let(:course) do
        create(:course, :open_on_apply, name: 'Primary', code: '2XT2', exposed_in_find: false)
      end
      let(:course_option) { create(:course_option, course:, vacancy_status: 'no_vacancies') }
      let(:application_form) { create(:application_form, :completed) }
      let(:application_choice) do
        create(:application_choice, :unsubmitted, course_option:, application_form:)
      end

      it 'renders error message' do
        expect(result.text).to include(
          'You cannot submit this application because there are no places left on the course.',
        )
        expect(result.text).to include(
          'You need to either remove this application or change your course.',
        )
      end
    end

    context 'when not exposed in find' do
      let(:course) do
        create(:course, :open_on_apply, name: 'Primary', code: '2XT2', exposed_in_find: false)
      end
      let(:course_option) { create(:course_option, course:, site_still_valid: false) }
      let(:application_form) { create(:application_form, :completed) }
      let(:application_choice) do
        create(:application_choice, :unsubmitted, course_option:, application_form:)
      end

      it 'renders error message' do
        expect(result.text).to include(
          'You cannot submit this application because it’s no longer available. You need to either remove it or change the course.',
        )
      end
    end

    context 'when site is invalid' do
      let(:course) do
        create(:course, :open_on_apply, name: 'Primary', code: '2XT2', applications_open_from: 2.days.from_now)
      end
      let(:course_option) { create(:course_option, course:, site_still_valid: false) }
      let(:application_form) { create(:application_form, :completed) }
      let(:application_choice) do
        create(:application_choice, :unsubmitted, course_option:, application_form:)
      end

      it 'renders error message' do
        expect(result.text).to include(
          'You cannot submit this application because it’s no longer available. You need to either remove it or change the course.',
        )
        expect(result.text).to include(
          "#{application_choice.current_provider.name} may be able to also recommend an alternative course.",
        )
      end
    end

    context 'when application is ready for submit' do
      let(:application_form) { create(:application_form, :completed, course_choices_completed: false) }
      let(:application_choice) { create(:application_choice, :unsubmitted, application_form:) }

      it 'renders the submit form' do
        expect(result.text).to include('Do you want to submit your application?Yes')
      end
    end
  end
end