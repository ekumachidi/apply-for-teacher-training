class ApplicationDates
  def initialize(application_form)
    @application_form = application_form
  end

  def submitted_at
    if @application_form.continuous_applications?
      @application_form.application_choices.pending_conditions.first&.sent_to_provider_at ||
        @application_form.submitted_at
    else
      @application_form.submitted_at
    end
  end

  def reject_by_default_at
    @application_form.application_choices.first&.reject_by_default_at
  end

  def decline_by_default_at
    @application_form.first_not_declined_application_choice.decline_by_default_at
  end
end
