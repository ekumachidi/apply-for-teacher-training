require 'rails_helper'

RSpec.describe CourseChoicesReviewComponent do
  context 'when course choices are editable' do
    let(:application_form) do
      create_application_form_with_course_choices(statuses: %w[application_complete])
    end

    it 'renders component with correct values for a course' do
      course_choice = application_form.application_choices.first
      result = render_inline(CourseChoicesReviewComponent, application_form: application_form)

      expect(result.css('.app-summary-card__title').text).to include(course_choice.provider.name)
      expect(result.css('.govuk-summary-list__key').text).to include('Course')
      expect(result.css('.govuk-summary-list__value').to_html).to include("#{course_choice.course.name} (#{course_choice.course.code})")
    end

    it 'renders component with correct values for a location' do
      course_choice = application_form.application_choices.first
      result = render_inline(CourseChoicesReviewComponent, application_form: application_form)

      expect(result.css('.govuk-summary-list__key').text).to include('Location')
      expect(result.css('.govuk-summary-list__value').to_html).to include(course_choice.site.name)
    end

    it 'renders component along with a delete link for each course' do
      course_id = application_form.application_choices.first.id
      result = render_inline(CourseChoicesReviewComponent, application_form: application_form)

      expect(result.css('.app-summary-card__actions').text).to include(t('application_form.courses.delete'))
      expect(result.css('.app-summary-card__actions a')[0].attr('href')).to include(
        Rails.application.routes.url_helpers.candidate_interface_confirm_destroy_course_choice_path(course_id),
      )
    end

    it 'renders component with correct values for multiple courses' do
      result = render_inline(CourseChoicesReviewComponent, application_form: application_form)

      application_form.application_choices.each do |course_choice|
        expect(result.css('.app-summary-card__title').text).to include(course_choice.provider.name)
      end
    end
  end

  context 'when course choices are not editable' do
    it 'renders component without a delete link and with a withdraw link' do
      application_form = create_application_form_with_course_choices(statuses: %w[application_complete])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false)

      expect(result.css('.app-summary-card__actions').text).not_to include(t('application_form.courses.delete'))
    end
  end

  context 'when course choices are submitted' do
    it 'renders component with the status as submitted when awaiting references' do
      application_form = create_application_form_with_course_choices(statuses: %w[awaiting_references])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.govuk-summary-list__key').text).to include('Status')
      expect(result.css('.govuk-summary-list__value').to_html).to include('Submitted')
    end

    it 'renders component with the status as submitted when application is complete' do
      application_form = create_application_form_with_course_choices(statuses: %w[application_complete])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.govuk-summary-list__key').text).to include('Status')
      expect(result.css('.govuk-summary-list__value').to_html).to include('Submitted')
    end

    it 'renders component with the status as pending when awaiting provider decision' do
      application_form = create_application_form_with_course_choices(statuses: %w[awaiting_provider_decision])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.govuk-summary-list__key').text).to include('Status')
      expect(result.css('.govuk-summary-list__value').to_html).to include('Pending')
    end

    it 'renders component with the status as offer when an offer has been made' do
      application_form = create_application_form_with_course_choices(statuses: %w[offer])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.govuk-summary-list__key').text).to include('Status')
      expect(result.css('.govuk-summary-list__value').to_html).to include('Offer')
    end

    it 'renders component with the status as accepted when the candidate has accepted an offer' do
      application_form = create_application_form_with_course_choices(statuses: %w[pending_conditions])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.govuk-summary-list__key').text).to include('Status')
      expect(result.css('.govuk-summary-list__value').to_html).to include('Accepted')
    end

    it 'renders component with the status as accepted when the candidate has declined an offer' do
      application_form = create_application_form_with_course_choices(statuses: %w[declined])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.govuk-summary-list__key').text).to include('Status')
      expect(result.css('.govuk-summary-list__value').to_html).to include('Declined')
    end
  end

  context 'when a course choice is awaiting provider decision' do
    let(:application_form) { create_application_form_with_course_choices(statuses: %w[awaiting_provider_decision]) }

    it 'renders component with a withdraw link' do
      course_id = application_form.application_choices.first.id

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.app-summary-card__actions').text).to include(t('application_form.courses.withdraw'))
      expect(result.css('.app-summary-card__actions a')[0].attr('href')).to include(
        Rails.application.routes.url_helpers.candidate_interface_course_choice_withdraw_path(course_id),
      )
    end

    it 'renders component with a withdrawal content' do
      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.text).to include(t('application_form.courses.withdrawal_information'))
    end
  end

  context 'when an offer has been made to a course choice' do
    it 'renders component with view and respond to offer link' do
      application_form = create_application_form_with_course_choices(statuses: %w[offer])

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.app-summary-card__actions').text).not_to include(t('application_form.courses.withdraw'))
      expect(result.css('.app-summary-card__actions').text).to include(t('application_form.courses.view_and_respond_to_offer'))
      expect(result.css('.app-summary-card__actions a')[0].attr('href')).to include('#')
    end
  end

  context 'when an offer has been accepted i.e. pending conditions' do
    let(:application_form) { create_application_form_with_course_choices(statuses: %w[pending_conditions]) }

    it 'renders component with a withdraw link' do
      course_id = application_form.application_choices.first.id

      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.css('.app-summary-card__actions').text).to include(t('application_form.courses.withdraw'))
      expect(result.css('.app-summary-card__actions a')[0].attr('href')).to include(
        Rails.application.routes.url_helpers.candidate_interface_course_choice_withdraw_path(course_id),
      )
    end

    it 'renders component with a withdrawal content' do
      result = render_inline(CourseChoicesReviewComponent, application_form: application_form, editable: false, show_status: true)

      expect(result.text).to include(t('application_form.courses.withdrawal_information'))
    end
  end

  def create_application_form_with_course_choices(statuses:)
    application_form = create(:application_form)

    statuses.each do |status|
      create(
        :application_choice,
        application_form: application_form,
        status: status,
      )
    end

    application_form
  end
end
