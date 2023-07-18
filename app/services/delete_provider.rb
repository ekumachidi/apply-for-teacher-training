class DeleteProvider
  include ImpersonationAuditHelper

  attr_reader :application_form

  def initialize(provider_id:)
    @provider_id = provider_id
  end

  def call!
    ActiveRecord::Base.transaction do
      provider.courses.map { |c| c.course_options.each { |co| co.application_choices.map(&:destroy!) } }
      provider.courses.each { |c| c.course_subjects.map(&:destroy!) }
      provider.sites.each(&:destroy!)
      provider.courses.each(&:destroy!)
      provider.vendor_api_tokens.each(&:destroy!)
      provider.vendor_api_requests.each(&:destroy!)
      provider.ratifying_provider_permissions.each { |rpp| rpp.provider_users.each(&:destroy!) }
      provider.ratifying_provider_permissions.each(&:destroy!)
      provider.training_provider_permissions.each(&:destroy!)
      provider.provider_agreements.destroy_all
      provider.destroy!
    end
  end

private

  def provider
    @provider ||= Provider.find(@provider_id)
  end
end
