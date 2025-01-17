require 'rails_helper'

RSpec.describe ProviderInterface::RejectionsController do
  include DfESignInHelpers
  include ModelWithErrorsStubHelper

  let(:provider_user) { create(:provider_user, :with_dfe_sign_in, :with_make_decisions) }
  let(:provider) { provider_user.providers.first }
  let(:course_option) { build(:course_option, course: build(:course, :open_on_apply, provider:)) }
  let(:application_choice) do
    create(:application_choice,
           status:,
           application_form: build(:application_form, :minimum_info),
           course_option:)
  end

  before do
    allow(DfESignInUser).to receive(:load_from_session)
      .and_return(
        DfESignInUser.new(
          email_address: provider_user.email_address,
          dfe_sign_in_uid: provider_user.dfe_sign_in_uid,
          first_name: provider_user.first_name,
          last_name: provider_user.last_name,
        ),
      )
  end

  describe 'GET edit' do
    context 'if application choice is in a rejectable state' do
      let(:status) { 'awaiting_provider_decision' }

      it 'responds with 200' do
        get new_provider_interface_rejection_path(application_choice)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'if application_choice is not rejectable' do
      let(:status) { 'rejected' }

      it 'responds with 404' do
        get new_provider_interface_rejection_path(application_choice)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
