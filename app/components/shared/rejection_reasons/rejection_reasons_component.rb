##
# This component class supports the rendering of rejection reasons from the current iteration of structured rejection reasons.
# See https://github.com/DFE-Digital/apply-for-teacher-training/blob/main/docs/reasons-for-rejection.md
#
class RejectionReasons::RejectionReasonsComponent < ViewComponent::Base
  include ViewHelper

  attr_reader :application_choice, :editable

  def initialize(application_choice:, render_link_to_find_when_rejected_on_qualifications: false, editable: false)
    @application_choice = application_choice
    @render_link_to_find_when_rejected_on_qualifications = render_link_to_find_when_rejected_on_qualifications
    @editable = editable
  end

  def paragraphs(input)
    return [] if input.blank?

    input.split("\r\n")
  end

  def link_to_find_when_rejected_on_qualifications(application_choice)
    link = govuk_link_to(
      'Find postgraduate teacher training courses',
      "#{I18n.t('find_postgraduate_teacher_training.production_url')}course/#{application_choice.provider.code}/#{application_choice.course.code}#section-entry",
    )

    "View the course requirements on #{link}.".html_safe
  end

  def editable?
    editable
  end

  def reasons
    ::RejectionReasons.new(application_choice.structured_rejection_reasons)
  end

  def render_link_to_find?(reason)
    reason.id == 'qualifications' && @render_link_to_find_when_rejected_on_qualifications
  end
end
