require 'rails_helper'

RSpec.describe 'CandidateInterface::BecomingATeacherController' do
  include Devise::Test::IntegrationHelpers
  let(:candidate) { create(:candidate) }
  let(:application_form) { create(:application_form, candidate: candidate) }
  let(:params) do
    {
      candidate_interface_becoming_a_teacher_form: {
        becoming_a_teacher: becoming_a_teacher,
      },
    }
  end

  before do
    sign_in candidate
  end

  describe 'GET /candidate/application/personal-statement' do
    it 'responds with 200' do
      get candidate_interface_new_becoming_a_teacher_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /candidate/application/personal-statement' do
    context 'when becoming_a_teacher with content' do
      let(:becoming_a_teacher) { 'Valid content' }

      it 'redirects to review page' do
        patch candidate_interface_new_becoming_a_teacher_path, params: params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(candidate_interface_becoming_a_teacher_show_path)
      end
    end

    context 'when becoming_a_teacher is blank' do
      let(:becoming_a_teacher) { '' }

      it 'redirects to application form page' do
        patch candidate_interface_new_becoming_a_teacher_path, params: params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(candidate_interface_application_form_path)
      end
    end

    context 'when becoming_a_teacher is invalid' do
      let(:becoming_a_teacher) { 'Some ' * 1001 }

      it 'redirects to review page' do
        patch candidate_interface_new_becoming_a_teacher_path, params: params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(candidate_interface_becoming_a_teacher_show_path)
      end
    end
  end

  describe 'PATCH /candidate/application/personal-statement/edit' do
    context 'when becoming_a_teacher is blank' do
      let(:becoming_a_teacher) { '' }

      it 'redirects to application form page' do
        patch candidate_interface_new_becoming_a_teacher_path, params: params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(candidate_interface_application_form_path)
      end
    end

    context 'when becoming_a_teacher is invalid' do
      let(:becoming_a_teacher) { 'Some ' * 1001 }

      it 'redirects to review page' do
        patch candidate_interface_edit_becoming_a_teacher_path, params: params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(candidate_interface_becoming_a_teacher_show_path)
      end
    end

    context 'when becoming_a_teacher with content' do
      let(:becoming_a_teacher) { 'Valid content' }

      it 'redirects to review page' do
        patch candidate_interface_edit_becoming_a_teacher_path, params: params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(candidate_interface_becoming_a_teacher_show_path)
      end
    end
  end
end