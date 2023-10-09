module CandidateInterface
  module ContinuousApplications
    class ApplicationChoiceSubmission
      include ActiveModel::Model
      attr_accessor :application_choice

      delegate :application_form, to: :application_choice
      # 1. Can not submit?
      #   apply_closed? && closed_for_applications?
      # 2. Course is unavailable
      #   course_full? || course_withdrawn
      # 3. Incompleted details
      #   incomplete_details? && science_gcse_not_needed?
      # 4. Complete details AND Science gcse needed
      #   only_science_gcse_incomplete?
      # 5.Incomplete details AND Science gcse needed
      #   incomplete_details? && science_gcse_needed? && science_gcse_incomplete?
      # 6. Submitted
      #   application_submitted?
      validates :application_choice, submittable: true
      # cycle_verification: true,
      # your_details_completion: true,
      # submission_availability: true,
      # open_for_applications: true,
      # course_availability: true,
      # can_add_more_choices: true
    end
  end
end
