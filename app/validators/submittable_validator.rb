# = Add error to Application submission`
#
# Add a single error based on prioritisation. The first error failure has it's
# message added to the validations
class SubmittableValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, application_choice)
    scenarios = %i[
      applications_closed
      course_unavailable
    ]

    error = scenarios.lazy.filter_map { |scenario| send(scenario, application_choice) }.first

    error && record.errors.add(
      attribute,
      error[:key],
      message: error[:message],
    )
  end

private

  def course_unavailable(application_choice)
    view = ActionView::Base.new(ActionView::LookupContext::DetailsKey.view_context_class(ActionView::Base), {}, ApplicationController.new)
    course = application_choice.current_course

    return if !course.full? &&
              application_choice.course_option.site_still_valid? &&
              course.exposed_in_find?

    {
      key: :course_unavailable,
      message: <<~MSG,
        You cannot submit this application as the course is no longer available.

        #{view.govuk_link_to('Remove this application', Rails.application.routes.url_helpers.candidate_interface_continuous_applications_confirm_destroy_course_choice_path(application_choice.id))} and search for other courses.
      MSG
    }
  end

  def applications_closed(application_choice)
    apply_open = CycleTimetable.can_submit?(application_choice.application_form)
    course_open = application_choice.current_course.open_for_applications?

    case [apply_open, course_open]
    in [true, true]
      return
    in [true, false] | [false, true]
      date = application_choice.course.applications_open_from.to_fs(:govuk_date)
    in [false, false]
      date = [CycleTimetable.apply_opens, application_choice.course.applications_open_from].max.to_fs(:govuk_date)
    end

    {
      key: :applications_closed,
      message: "This course is not yet open to applications. You’ll be able to submit your application on #{date}.",
    }
  end
end
