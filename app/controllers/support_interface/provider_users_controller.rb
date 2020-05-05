module SupportInterface
  class ProviderUsersController < SupportInterfaceController
    def index
      @provider_users = ProviderUser.includes(:providers).all
    end

    def new
      @form = ProviderUserForm.new
    end

    def create
      @form = ProviderUserForm.new(provider_user_params.merge(provider_permissions: provider_permissions_params))
      provider_user = @form.build
      service = SaveAndInviteProviderUser.new(
        form: @form,
        save_service: SaveProviderUser.new(
          provider_user: provider_user,
          provider_permissions: @form.provider_permissions,
        ),
        invite_service: InviteProviderUser.new(provider_user: provider_user),
      )

      render :new and return unless service.call

      flash[:success] = 'Provider user created'
      redirect_to support_interface_provider_users_path
    end

    def edit
      provider_user = ProviderUser.find(params[:id])
      @form = ProviderUserForm.from_provider_user(provider_user)
    end

    def update
      provider_user = ProviderUser.find(params[:id])

      @form = ProviderUserForm.new(
        provider_user_params.merge(
          provider_user: provider_user,
          provider_permissions: provider_permissions_params,
        ),
      )

      service = SaveProviderUser.new(
        provider_user: provider_user,
        provider_permissions: @form.provider_permissions,
        deselected_provider_permissions: @form.deselected_provider_permissions,
      )

      if service.call!
        flash[:success] = 'Provider user updated'
        redirect_to edit_support_interface_provider_user_path(provider_user)
      else
        render :edit
      end
    end

    def audits
      @provider_user = ProviderUser.find(params[:provider_user_id])
    end

  private

    def provider_user_params
      params.require(:support_interface_provider_user_form)
        .permit(:email_address, :first_name, :last_name)
    end

    def provider_permissions_params
      params.require(:support_interface_provider_user_form)
            .permit(provider_permissions_forms: {})
            .fetch(:provider_permissions_forms, {})
            .to_h
    end
  end
end
