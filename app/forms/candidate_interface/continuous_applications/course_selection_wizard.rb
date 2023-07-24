module CandidateInterface
  module ContinuousApplications
    class CourseSelectionStore < DfE::WizardStore
      delegate :current_application, to: :wizard
      attr_accessor :application_choice

      def save
        return :skipped unless wizard.completed?

        course_option = Course.find(course_id).course_options.available.first

        @application_choice = current_application.application_choices.new
        @application_choice.configure_initial_course_choice!(course_option)
        @application_choice
      end

      delegate :course_id, to: :current_step
    end

    class CourseSelectionWizard < DfE::Wizard
      attr_accessor :current_application

      steps do
        [
          { do_you_know_the_course: DoYouKnowTheCourseStep },
          { go_to_find_explanation: GoToFindExplanationStep },
          { provider_selection: ProviderSelectionStep },
          { which_course_are_you_applying_to: WhichCourseAreYouApplyingToStep },
          { course_study_mode: CourseStudyModeStep },
          { course_site: CourseSiteStep },
          { course_review: CourseReviewStep },
        ]
      end

      store CourseSelectionStore

      def logger
        DfE::Wizard::Logger.new(Rails.logger, if: -> { Rails.env.development? })
      end

      def completed?
        current_step.respond_to?(:completed?) && current_step.completed?
      end
    end
  end
end
