module VendorAPI
  class SingleApplicationPresenter
    include Rails.application.routes.url_helpers

    def initialize(application_choice)
      @application_choice = application_choice
      @application_form = application_choice.application_form
    end

    def as_json
      hash = {
        id: application_choice.id.to_s,
        type: 'application',
        attributes: {
          support_reference: application_form.support_reference,
          status: status,
          phase: application_form.phase,
          updated_at: application_choice.updated_at.iso8601,
          submitted_at: application_form.submitted_at.iso8601,
          personal_statement: personal_statement,
          interview_preferences: application_form.interview_preferences,
          reject_by_default_at: application_choice.reject_by_default_at&.iso8601,
          recruited_at: application_choice.recruited_at,
          candidate: {
            id: "C#{application_form.candidate.id}",
            first_name: application_form.first_name,
            last_name: application_form.last_name,
            date_of_birth: application_form.date_of_birth,
            nationality: nationalities,
            domicile: application_form.country,
            uk_residency_status: uk_residency_status,
            english_main_language: application_form.english_main_language,
            english_language_qualifications: application_form.english_language_details,
            other_languages: application_form.other_language_details,
            disability_disclosure: application_form.disability_disclosure,
          },
          contact_details: contact_details,
          course: course_info_for(application_choice.course_option),
          references: references,
          qualifications: qualifications,
          work_experience: {
            jobs: work_experience_jobs,
            volunteering: work_experience_volunteering,
            work_history_break_explanation: work_history_breaks,
          },
          offer: offer,
          hesa_itt_data: hesa_itt_data,
          rejection: get_rejection,
          withdrawal: withdrawal,
          further_information: application_form.further_information,
          safeguarding_issues_status: application_form.safeguarding_issues_status,
          safeguarding_issues_details_url: safeguarding_issues_details_url,
        },
      }
      if application_choice.status == 'enrolled'
        hash[:attributes][:hesa_itt_data] = hesa_itt_data
      end
      hash
    end

  private

    attr_reader :application_choice, :application_form

    # V2: for backwards compatibility `offer_withdrawn` state is displayed as `rejected` in the API.
    def status
      if application_choice.offer_withdrawn?
        'rejected'
      else
        application_choice.status
      end
    end

    def get_rejection
      if application_choice.rejection_reason?
        {
          reason: application_choice.rejection_reason,
          date: application_choice.rejected_at.iso8601,
        }
      elsif application_choice.offer_withdrawal_reason?
        {
          reason: application_choice.offer_withdrawal_reason,
          date: application_choice.offer_withdrawn_at.iso8601,
        }
      end
    end

    def withdrawal
      return unless application_choice.withdrawn?

      {
        reason: nil, # Candidates are not able to provide a withdrawal reason yet
        date: application_choice.withdrawn_at.iso8601,
      }
    end

    def nationalities
      [
        application_form.first_nationality,
        application_form.second_nationality,
        application_form.third_nationality,
        application_form.fourth_nationality,
        application_form.fifth_nationality,
      ].map { |n| NATIONALITIES_BY_NAME[n] }.compact.uniq
        .sort.partition { |e| %w[GB IE].include? e }.flatten
    end

    def uk_residency_status
      return 'UK Citizen' if nationalities.include?('GB')

      return 'Irish Citizen' if nationalities.include?('IE')

      return application_form.right_to_work_or_study_details if application_form.right_to_work_or_study_yes?

      return 'Candidate needs to apply for permission to work and study in the UK' if application_form.right_to_work_or_study_no?

      'Candidate does not know'
    end

    def course_info_for(course_option)
      {
        recruitment_cycle_year: course_option.course.recruitment_cycle_year,
        provider_code: course_option.course.provider.code,
        site_code: course_option.site.code,
        course_code: course_option.course.code,
        study_mode: course_option.study_mode,
        start_date: course_option.course.start_date.strftime('%Y-%m'),
      }
    end

    def work_experience_jobs
      application_form.application_work_experiences.map do |experience|
        experience_to_hash(experience)
      end
    end

    def work_experience_volunteering
      application_form.application_volunteering_experiences.map do |experience|
        experience_to_hash(experience)
      end
    end

    def experience_to_hash(experience)
      {
        id: experience.id,
        start_date: experience.start_date.to_date,
        end_date: experience.end_date&.to_date,
        role: experience.role,
        organisation_name: experience.organisation,
        working_with_children: experience.working_with_children,
        commitment: experience.commitment,
        description: experience_description(experience),
      }
    end

    def experience_description(experience)
      return experience.details if experience.working_pattern.blank?

      "Working pattern: #{experience.working_pattern}\n\nDescription: #{experience.details}"
    end

    def references
      application_form.application_references.feedback_provided.map do |reference|
        reference_to_hash(reference)
      end
    end

    def reference_to_hash(reference)
      {
        id: reference.id,
        name: reference.name,
        email: reference.email_address,
        relationship: reference.relationship,
        reference: reference.feedback,
        referee_type: reference.referee_type,
        safeguarding_concerns: reference.has_safeguarding_concerns_to_declare?,
      }
    end

    def qualifications
      {
        gcses: format_gcses,
        degrees: qualifications_of_level('degree').map { |q| qualification_to_hash(q) },
        other_qualifications: qualifications_of_level('other').map { |q| qualification_to_hash(q) },
        missing_gcses_explanation: ApplicationDataService.missing_gcses_explanation(application_form: application_form),
      }
    end

    def format_gcses
      gcses = qualifications_of_level('gcse').reject(&:missing_qualification?)
      parsed_gcses = parse_structured_gcses(gcses)
      parsed_gcses.map { |q| qualification_to_hash(q) }
    end

    def parse_structured_gcses(gcses)
      multiple_gcses = gcses.select { |gcse| gcse[:subject] != 'science triple award' && gcse[:structured_grades].present? }

      if multiple_gcses.any?
        multiple_gcses.each do |multiple_gcse|
          structured_grades = JSON.parse(multiple_gcse[:structured_grades])

          structured_grades.each do |k, v|
            new_separated_gcse = multiple_gcse.dup
            new_separated_gcse.subject = k.humanize
            new_separated_gcse.grade = v
            gcses << new_separated_gcse
          end

          gcses.delete_if { |gcse| gcse == multiple_gcse }
        end
      end
      gcses
    end

    def qualifications_of_level(level)
      # NOTE: we do it this way so that it uses the already-included relation
      # rather than triggering separate queries, as it does if we use the scopes
      # .gcses .degrees etc
      application_form.application_qualifications.select do |q|
        q.level == level
      end
    end

    def qualification_to_hash(qualification)
      {
        id: qualification.id,
        qualification_type: qualification.qualification_type,
        non_uk_qualification_type: qualification.non_uk_qualification_type,
        subject: qualification.subject,
        grade: grade_details(qualification),
        start_year: qualification.start_year,
        award_year: qualification.award_year,
        institution_details: institution_details(qualification),
        awarding_body: qualification.awarding_body,
        equivalency_details: ApplicationDataService.composite_equivalency_details(qualification: qualification),
      }.merge HesaQualificationFieldsPresenter.new(qualification).to_hash
    end

    def grade_details(qualification)
      grade = nil

      if qualification.grade
        if qualification.predicted_grade
          grade = "#{qualification.grade} (Predicted)"
        else
          grade = qualification.grade
        end
      end

      grades = qualification.structured_grades

      # For triple award science we need to serialize 'grades' to the 'grade' field
      # in the specified order
      if qualification.subject == 'science triple award' && grades
        grade = "#{grades['biology']}#{grades['chemistry']}#{grades['physics']}"
      end

      grade
    end

    def institution_details(qualification)
      if qualification.institution_name
        [qualification.institution_name, qualification.institution_country].compact.join(', ')
      end
    end

    def personal_statement
      "Why do you want to become a teacher?: #{application_form.becoming_a_teacher} \n What is your subject knowledge?: #{application_form.subject_knowledge}"
    end

    def contact_details
      if application_form.international?
        {
          phone_number: application_form.phone_number,
          address_line1: application_form.international_address,
          country: application_form.country,
          email: application_form.candidate.email_address,
        }
      else
        {
          phone_number: application_form.phone_number,
          address_line1: application_form.address_line1,
          address_line2: application_form.address_line2,
          address_line3: application_form.address_line3,
          address_line4: application_form.address_line4,
          postcode: application_form.postcode,
          country: application_form.country,
          email: application_form.candidate.email_address,
        }
      end
    end

    def offered_course
      offered_option = application_choice.offered_course_option || application_choice.course_option

      {
        course: course_info_for(offered_option),
      }
    end

    def offer
      return nil if application_choice.offer.nil?

      application_choice.offer
        .merge(offered_course)
        .merge({
          offer_made_at: application_choice.offered_at,
          offer_accepted_at: application_choice.accepted_at,
          offer_declined_at: application_choice.declined_at,
        })
    end

    def hesa_itt_data
      equality_and_diversity_data = application_form&.equality_and_diversity

      if equality_and_diversity_data
        {
          sex: equality_and_diversity_data['hesa_sex'],
          disability: equality_and_diversity_data['hesa_disabilities'],
          ethnicity: equality_and_diversity_data['hesa_ethnicity'],
        }
      end
    end

    def work_history_breaks
      # With the new feature of adding individual work history breaks, `application_form.work_history_breaks`
      # is a legacy column. So we'll need to check if an application form has this value first.
      if application_form.work_history_breaks
        application_form.work_history_breaks
      elsif application_form.application_work_history_breaks.any?
        breaks = application_form.application_work_history_breaks.map do |work_break|
          start_date = work_break.start_date.to_s(:month_and_year)
          end_date = work_break.end_date.to_s(:month_and_year)

          "#{start_date} to #{end_date}: #{work_break.reason}"
        end

        breaks.join("\n\n")
      else
        ''
      end
    end

    def safeguarding_issues_details_url
      application_form.has_safeguarding_issues_to_declare? ? provider_interface_application_choice_url(application_choice, anchor: 'criminal-convictions-and-professional-misconduct') : nil
    end
  end
end
