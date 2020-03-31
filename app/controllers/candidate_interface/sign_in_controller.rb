module CandidateInterface
  class SignInController < CandidateInterfaceController
    skip_before_action :authenticate_candidate!
    before_action :redirect_to_application_if_signed_in, except: %i[authenticate]

    def new
      if FeatureFlag.active?('improved_expired_token_flow') && params[:u]
        redirect_to candidate_interface_expired_sign_in_path(u: params[:u])
      else
        @candidate = Candidate.new
      end
    end

    def create
      @candidate = Candidate.for_email candidate_params[:email_address]

      course_from_find_params = Provider
        .find_by(code: params[:providerCode])
        &.courses
        &.find_by(code: params[:courseCode])

      if @candidate.persisted?
        if course_from_find_params.present?
          @candidate.update(course_from_find_id: course_from_find_params.id)
        end

        MagicLinkSignIn.call(candidate: @candidate)
        add_identity_to_log @candidate.id
        redirect_to candidate_interface_check_email_sign_in_path
      elsif @candidate.valid?
        AuthenticationMailer.sign_in_without_account_email(to: @candidate.email_address).deliver_now
        redirect_to candidate_interface_check_email_sign_in_path
      else
        render :new
      end
    end

    def authenticate
      candidate = FindCandidateByToken.call(raw_token: params[:token])
      token_not_expired = FindCandidateByToken.token_not_expired?(candidate)

      if candidate.nil? && FeatureFlag.active?('improved_expired_token_flow') && params[:u]
        candidate_id = Encryptor.decrypt(params[:u])
        candidate = Candidate.find(candidate_id) if candidate_id
      end

      if candidate.nil?
        redirect_to action: :new
      elsif token_not_expired
        flash[:success] = t('apply_from_find.account_created_message') if candidate.last_signed_in_at.nil?
        sign_in(candidate, scope: :candidate)
        add_identity_to_log candidate.id
        candidate.update!(last_signed_in_at: Time.zone.now)

        redirect_to candidate_interface_interstitial_path(providerCode: params[:providerCode], courseCode: params[:courseCode])
      else
        # rubocop:disable Style/IfInsideElse
        if FeatureFlag.active?('improved_expired_token_flow')
          encrypted_candidate_id = Encryptor.encrypt(candidate.id)
          redirect_to candidate_interface_expired_sign_in_path(u: encrypted_candidate_id)
        else
          redirect_to action: :new
        end
        # rubocop:enable Style/IfInsideElse
      end
    end

    def expired
      raise unless FeatureFlag.active?('improved_expired_token_flow')

      if params[:u].blank?
        redirect_to candidate_interface_sign_in_path
      end
    end

    def create_from_expired_token
      render_404 unless FeatureFlag.active?('improved_expired_token_flow')

      candidate_id = Encryptor.decrypt(params.fetch(:u))
      if candidate_id
        candidate = Candidate.find(candidate_id)
        MagicLinkSignIn.call(candidate: candidate)
        add_identity_to_log candidate.id
        redirect_to candidate_interface_check_email_sign_in_path
      else
        render 'errors/not_found', status: :forbidden
      end
    end

  private

    def candidate_params
      params.require(:candidate).permit(:email_address)
    end
  end
end
