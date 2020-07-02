module ProviderInterface
  module StatusBoxComponents
    class RejectedComponent < ViewComponent::Base
      include ViewHelper
      include StatusBoxComponents::CourseRows

      attr_reader :application_choice

      def initialize(application_choice:, options: {})
        @application_choice = application_choice
        @options = options
      end

      def render?
        application_choice.rejected? || \
          raise(ProviderInterface::StatusBoxComponent::ComponentMismatchError)
      end

      def rejected_rows
        [
          {
            key: 'Status',
            value: render(ProviderInterface::ApplicationStatusTagComponent.new(application_choice: application_choice)),
          },
          {
            key: 'Application rejected',
            value: application_choice.rejected_at.to_s(:govuk_date),
          },
        ]
      end
    end
  end
end
