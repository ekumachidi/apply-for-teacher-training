class GetUnsubmittedApplicationsReadyToNudge
  MAILER = 'candidate_mailer'.freeze
  MAIL_TEMPLATE = 'nudge_unsubmitted'.freeze
  COMMON_COMPLETION_ATTRS = %w[
    course_choices_completed
    degrees_completed
    other_qualifications_completed
    volunteering_completed
    work_history_completed
    personal_details_completed
    contact_details_completed
    english_gcse_completed
    maths_gcse_completed
    training_with_a_disability_completed
    safeguarding_issues_completed
    becoming_a_teacher_completed
    subject_knowledge_completed
    interview_preferences_completed
    references_completed
  ].freeze
  SCIENCE_GCSE_COMPLETION_ATTR = 'science_gcse_completed'.freeze
  EFL_COMPLETION_ATTR = 'efl_completed'.freeze

  def call
    uk_and_irish_names = NATIONALITIES.select do |code, _name|
      code.in?(ApplicationForm::BRITISH_OR_IRISH_NATIONALITIES)
    end.map(&:second)
    uk_and_irish = uk_and_irish_names.map { |name| ActiveRecord::Base.connection.quote(name) }.join(',')

    ApplicationForm
      .where(submitted_at: nil)
      .where('application_forms.updated_at < ?', 7.days.ago)
      .where(recruitment_cycle_year: RecruitmentCycle.current_year)
      .where(COMMON_COMPLETION_ATTRS.map { |attr| "#{attr} = true" }.join(' AND '))
      .where(
        'NOT EXISTS (:existing_email)',
        existing_email: Email
          .select(1)
          .where('emails.application_form_id = application_forms.id')
          .where(mailer: MAILER)
          .where(mail_template: MAIL_TEMPLATE),
      )
      .and(ApplicationForm
        .where(science_gcse_completed: true)
        .or(
          ApplicationForm.where(
            'NOT EXISTS (:primary)',
            primary: ApplicationChoice
              .select(1)
              .joins(:course)
              .where('application_choices.application_form_id = application_forms.id')
              .where('courses.level': 'primary'),
          ),
        ))
      .and(ApplicationForm
        .where(efl_completed: true)
        .or(
          ApplicationForm.where(
            "first_nationality IN (#{uk_and_irish})",
          ),
        ))
  end
end
