module CandidateInterface
  class ImmigrationStatusForm
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks

    attr_accessor :immigration_status, :right_to_work_or_study_details, :nationalities

    validates :immigration_status, presence: true
    validates :right_to_work_or_study_details, presence: true, if: :other_immigration_status?
    validates :right_to_work_or_study_details, word_count: { maximum: 200 }

    def self.build_from_application(application_form)
      new(
        immigration_status: application_form.immigration_status,
        right_to_work_or_study_details: application_form.right_to_work_or_study_details,
        nationalities: application_form.nationalities,
      )
    end

    def save(application_form)
      return false unless valid?

      application_form.update(
        immigration_status:,
        right_to_work_or_study_details: other_immigration_status? ? right_to_work_or_study_details : nil,
      )
    end

    def eu_nationality?
      return false if nationalities.blank?

      EU_EEA_SWISS_COUNTRY_CODES.intersect?(nationalities.map { |name| NATIONALITIES_BY_NAME[name] })
    end

    def other_immigration_status?
      immigration_status == 'other'
    end
  end
end
