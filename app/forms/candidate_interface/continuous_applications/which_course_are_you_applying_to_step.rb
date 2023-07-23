module CandidateInterface
  module ContinuousApplications
    class WhichCourseAreYouApplyingToStep < DfE::WizardStep
      attr_accessor :provider_id, :course_id
      validates :provider_id, :course_id, presence: true

      def self.permitted_params
        %i[provider_id course_id]
      end

      def available_courses
        @available_courses ||= GetAvailableCoursesForProvider.new(provider).call
      end

      def dropdown_available_courses
        ::CandidateInterface::PickCourseForm.new(provider_id:).dropdown_available_courses
      end

      def next_step
        return :course_review if completed?

        if multiple_study_modes?
          :course_study_mode
        elsif multiple_sites?
          :course_site
        else
          :course_review
        end
      end

      def completed?
        !multiple_study_modes? && !multiple_sites?
      end

      def multiple_study_modes?
        course.currently_has_both_study_modes_available?
      end

      def multiple_sites?
        course.course_options.available.many?
      end

      def provider
        @provider ||= Provider.find(provider_id)
      end

      def course
        @course ||= provider.courses.find(course_id)
      end
    end
  end
end
