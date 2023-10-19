class WorkHistoryAndUnpaidExperienceComponent < WorkHistoryComponent
  def initialize(application_form:)
    @application_form = application_form
    @work_history_with_breaks ||= WorkHistoryWithBreaks.new(application_form, include_unpaid_experience: true)
  end

  def subtitle
    if work_history? && unpaid_experience?
      'Details of work history and unpaid experience'
    elsif work_history?
      'Details of work history'
    elsif unpaid_experience?
      'Details of unpaid experience'
    end
  end

  def render?
    true
  end

  def rows
    [
      work_history_row,
      unpaid_experience_row,
    ]
  end

private

  def work_history_row
    row = {
      key: 'Do you have any work history',
      value: work_history_text,
    }

    return row unless editable?

    row.merge(
      action: {
        href: support_interface_application_form_edit_work_history_path(application_form),
        visually_hidden_text: 'work history',
      },
    )
  end

  def unpaid_experience_row
    {
      key: 'Do you have any unpaid experience',
      value: unpaid_experience_text,
    }
  end

  def work_history_text
    I18n.t("application_form.restructured_work_history.#{work_history_status}.label")
  end

  def unpaid_experience_text
    unpaid_experience? ? 'Yes' : 'No'
  end

  delegate :work_history_status, to: :application_form

  def work_history?
    work_history_with_breaks.work_history.any?
  end

  def unpaid_experience?
    work_history_with_breaks.unpaid_work.any?
  end

  def editable?
    @application_form.editable?
  end
end
