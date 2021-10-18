module MinisterialReport
  SUBJECTS = %i[
    art_and_design
    biology
    business_studies
    chemistry
    classics
    computing
    design_and_technology
    drama
    english
    geography
    history
    mathematics
    modern_foreign_languages
    music
    other
    physical_education
    physics
    religious_education
    stem
    ebacc
    primary
    secondary
  ].freeze

  STEM_SUBJECTS = %i[
    mathematics
    biology
    chemistry
    physics
    computing
  ].freeze

  EBACC_SUBJECTS = %i[
    english
    mathematics
    biology
    chemistry
    physics
    computing
    geography
    history
    modern_foreign_languages
    classics
  ].freeze

  SECONDARY_SUBJECTS = %i[
    art_and_design
    biology
    business_studies
    chemistry
    classics
    computing
    design_and_technology
    drama
    english
    geography
    history
    mathematics
    modern_foreign_languages
    music
    other
    physical_education
    physics
    religious_education
  ].freeze

  SUBJECT_CODE_MAPPINGS = {
    '00' => :primary,
    '01' => :primary,
    '02' => :primary,
    '03' => :primary,
    '04' => :primary,
    '06' => :primary,
    '07' => :primary,
    'W1' => :art_and_design,
    'F0' => :physics,
    'F3' => :physics,
    'C1' => :biology,
    '08' => :business_studies,
    'L1' => :business_studies,
    'F1' => :chemistry,
    '09' => :other,
    'P3' => :other,
    'L5' => :other,
    'P1' => :other,
    'C8' => :other,
    '14' => :other,
    '41' => :other,
    'Q8' => :classics,
    '11' => :computing,
    '12' => :physical_education,
    'C6' => :physical_education,
    'DT' => :design_and_technology,
    '13' => :drama,
    'Q3' => :english,
    'F8' => :geography,
    'V1' => :history,
    'G1' => :mathematics,
    'W3' => :music,
    'V6' => :religious_education,
    '15' => :modern_foreign_languages,
    '16' => :modern_foreign_languages,
    '17' => :modern_foreign_languages,
    '18' => :modern_foreign_languages,
    '19' => :modern_foreign_languages,
    '20' => :modern_foreign_languages,
    '21' => :modern_foreign_languages,
    '22' => :modern_foreign_languages,
    '24' => :modern_foreign_languages,
  }.freeze

  APPLICATIONS_REPORT_STATUS_MAPPING = {
    unsubmitted: %i[applications],
    application_not_sent: %i[applications],
    awaiting_provider_decision: %i[applications],
    offer: %i[applications offer_received],
    pending_conditions: %i[applications offer_received accepted],
    rejected: %i[applications application_rejected],
    cancelled: %i[applications application_declined],
    offer_deferred: %i[applications offer_received accepted],
    interviewing: %i[applications],
    offer_withdrawn: %i[applications application_withdrawn],
    conditions_not_met: %i[applications offer_received],
    declined: %i[applications application_declined],
    recruited: %i[applications offer_received accepted],
    withdrawn: %i[applications application_withdrawn],
  }.freeze

  CANDIDATES_REPORT_STATUS_MAPPING = {
    unsubmitted: %i[candidates],
    application_not_sent: %i[candidates],
    awaiting_provider_decision: %i[candidates],
    offer: %i[candidates candidates_holding_offers],
    pending_conditions: %i[candidates candidates_holding_offers candidates_that_have_accepted_offers],
    rejected: %i[candidates rejected_candidates],
    cancelled: %i[candidates declined_candidates],
    offer_deferred: %i[candidates candidates_holding_offers candidates_that_have_accepted_offers],
    interviewing: %i[candidates],
    offer_withdrawn: %i[candidates candidates_that_have_withdrawn_offers],
    conditions_not_met: %i[candidates candidates_holding_offers],
    declined: %i[candidates declined_candidates],
    recruited: %i[candidates candidates_holding_offers candidates_that_have_accepted_offers],
    withdrawn: %i[candidates],
  }.freeze

  def self.determine_dominant_course_subject_for_report(course_name, course_level, subject_names_and_codes)
    subject_names = subject_names_and_codes.keys

    # is there only one subject?
    subject = subject_names.first if subject_names.size == 1

    # is subject first in the course name?
    if !subject
      subject = subject_names.find do |subject_name|
        course_name.split.first.downcase.in?(subject_name.to_s.downcase)
      end
    end

    # is subject in the course name at all?
    if !subject
      subject = subject_names.find do |subject_name|
        subject_name.to_s.downcase.in?(course_name.downcase)
      end
    end

    subject_code_for_report = subject_names_and_codes[subject]

    SUBJECT_CODE_MAPPINGS[subject_code_for_report].presence || course_level.downcase.to_sym
  end
end