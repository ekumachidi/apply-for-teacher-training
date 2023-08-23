module CandidateInterface
  module ContinuousApplications
    class ApplicationReviewComponent < ViewComponent::Base
      attr_reader :application_choice
      delegate :unsubmitted?, :current_course, :current_course_option, to: :application_choice

      def initialize(application_choice:)
        @application_choice = application_choice
      end

      def rows
        [
          course_info_row,
          study_mode_row,
          location_row,
        ]
      end

      def course_info_row
        {
          key: 'Course',
          value: current_course.name_and_code,
        }.tap do |row|
          if unsubmitted?
            row[:action] = {
              href: candidate_interface_edit_continuous_applications_which_course_are_you_applying_to_path(application_choice.id),
              visually_hidden_text: "course for #{current_course.name_and_code}",
            }
          end
        end
      end

      def study_mode_row
        {
          key: 'Study mode',
          value: current_course_option.study_mode.humanize.to_s,
        }.tap do |row|
          if unsubmitted? && current_course.currently_has_both_study_modes_available?
            row[:action] = {
              href: candidate_interface_edit_continuous_applications_course_study_mode_path(application_choice.id, current_course.id),
              visually_hidden_text: "study mode for #{current_course.name_and_code}",
            }
          end
        end
      end

      def location_row
        {
          key: 'Location',
          value: current_course_option.site_name,
        }.tap do |row|
          if unsubmitted? && current_course.multiple_sites?
            row[:action] = {
              href: candidate_interface_edit_continuous_applications_course_site_path(application_choice.id, current_course.id, current_course_option.study_mode),
              visually_hidden_text: "location for #{current_course.name_and_code}",
            }
          end
        end
      end
    end
  end
end