module CandidateInterface
  class OfferDashboardController < CandidateInterfaceController
    before_action :redirect_to_completed_dashboard_if_not_accepted
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    before_action :set_reference, :redirect_to_review_if_application_not_requested_yet, only: %i[view_reference]

    def show
      @application_form = current_application
      @application_choice_with_offer = current_application.application_choices.pending_conditions.first
      @accepted_offer_provider_name = @application_choice_with_offer.provider.name
    end

  private

    def redirect_to_review_if_application_not_requested_yet
      redirect_to candidate_interface_new_references_request_reference_review_path(@reference) if @reference.not_requested_yet?
    end

    def set_reference
      @reference ||= current_application.application_references.find(params[:id])
    end
  end
end