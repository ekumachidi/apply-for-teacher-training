module SupportInterface
  class ProviderUserForm
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :first_name, :last_name, :provider_user
    attr_writer :provider_ids
    attr_reader :email_address

    validates :email_address, :first_name, :last_name, presence: true
    validates :email_address, email: true
    validates :provider_ids, presence: true
    validate :email_is_unique

    def build
      return unless valid?

      @provider_user ||= ProviderUser.new
      @provider_user.first_name = first_name
      @provider_user.last_name = last_name
      @provider_user.email_address = email_address
      @provider_user.provider_ids = provider_ids
      @provider_user if @provider_user.valid?
    end

    def save
      if build
        @provider_user.save!
        assign_manage_users_permissions if manage_users
        @provider_user
      end
    end

    def email_address=(raw_email_address)
      @email_address = raw_email_address.downcase.strip
    end

    def available_providers
      @available_providers ||= Provider.order(name: :asc)
    end

    def persisted?
      @provider_user && @provider_user.persisted?
    end

    def self.from_provider_user(provider_user)
      new(
        provider_user: provider_user,
        first_name: provider_user.first_name,
        last_name: provider_user.last_name,
        email_address: provider_user.email_address,
        provider_ids: provider_user.provider_ids,
        manage_users: provider_user.can_manage_users?,
      )
    end

    def provider_ids
      return [] unless @provider_ids

      @provider_ids.reject(&:blank?)
    end

  private

    def email_is_unique
      return if persisted? && provider_user.email_address == email_address

      return unless ProviderUser.exists?(email_address: email_address)

      errors.add(:email_address, 'This email address is already in use')
    end

    def assign_manage_users_permissions
      ProviderPermissions.where(
        provider_user_id: provider_user.id,
        provider_id: provider_ids,
      ).update_all(manage_users: true)
    end
  end
end
