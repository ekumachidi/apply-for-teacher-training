module CandidateInterface
  module ContinuousApplications
    class ApplicationReviewComponent < ViewComponent::Base
      attr_reader :application_choice
      delegate :unsubmitted?, :current_course, :current_course_option, to: :application_choice

      def initialize(application_choice:)
        @application_choice = application_choice
      end

      def show_personal_statement?
        @application_choice.submitted? && @application_choice.personal_statement.present?
      end

      def rows
        [
          status_row,
          application_number_row,
          submitted_at_row,
          course_info_row,
          qualifications_row,
          course_length_row,
          study_mode_row,
          location_row,
        ].compact
      end

      def status_row
        return unless application_choice.sent_to_provider_at

        {
          key: 'Status',
          value: render(
            ApplicationStatusTagComponent.new(application_choice:, display_info_text: false),
          ),
        }
      end

      def application_number_row
        return unless application_choice.sent_to_provider_at

        { key: 'Application number', value: application_choice.id }
      end

      def submitted_at_row
        return unless application_choice.sent_to_provider_at

        { key: 'Application submitted', value: "#{application_choice.sent_to_provider_at.to_fs(:govuk_date_and_time)} (#{time_ago_in_words(application_choice.sent_to_provider_at)} ago)" }
      end

      def course_info_row
        {
          key: 'Course',
          value: govuk_link_to(current_course.name_and_code, "https://www.find-postgraduate-teacher-training.service.gov.uk/course/#{current_course.provider.code}/#{current_course.code}", { target: '_blank', rel: 'noopener' }),
        }.tap do |row|
          if unsubmitted?
            row[:action] = {
              href: candidate_interface_edit_continuous_applications_which_course_are_you_applying_to_path(application_choice.id),
              visually_hidden_text: "course for #{current_course.name_and_code}",
            }
          end
        end
      end

      def qualifications_row
        {
          key: 'Qualifications',
          value: current_course.qualifications_to_s,
        }
      end

      def course_length_row
        formatted = {
          'OneYear' => '1 year',
          'TwoYears' => '2 years',
        }

        value = formatted[current_course.course_length] || current_course.course_length || 'unset'

        {
          key: 'Course length',
          value:,
        }
      end

      def study_mode_row
        {
          key: 'Full time or part time',
          value: current_course_option.study_mode.humanize.to_s,
        }.tap do |row|
          if unsubmitted? && current_course.currently_has_both_study_modes_available?
            row[:action] = {
              href: candidate_interface_edit_continuous_applications_course_study_mode_path(application_choice.id, current_course.id),
              visually_hidden_text: "full time or part time for #{current_course.name_and_code}",
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
