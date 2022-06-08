require 'load_test'

namespace :load_test do
  desc 'Set up the Apply load test application with data from the Teacher training public API'
  task setup_app_data: :environment do
    Rails.logger.info 'Syncing data from TTAPI...'

    LoadTest::PROVIDER_CODES.each do |code|
      provider_from_api = TeacherTrainingPublicAPI::Provider
          .where(year: RecruitmentCycle.current_year)
          .find(code).first

      TeacherTrainingPublicAPI::SyncSubjects.new.perform

      TeacherTrainingPublicAPI::SyncProvider.new(
        provider_from_api: provider_from_api, recruitment_cycle_year: RecruitmentCycle.previous_year,
      ).call(run_in_background: false)

      Provider.find_by(code: code).courses.previous_cycle.exposed_in_find.update_all(open_on_apply: true, opened_on_apply_at: Time.zone.now)

      TeacherTrainingPublicAPI::SyncProvider.new(
        provider_from_api: provider_from_api, recruitment_cycle_year: RecruitmentCycle.current_year,
      ).call(run_in_background: false)

    rescue JsonApiClient::Errors::NotFound
      Rails.logger.warn "Could not find Provider for code #{code}. Skipping."
    end
  end

  desc 'Set up provider users for load test seed organisations'
  task setup_provider_users: :environment do
    LoadTest::PROVIDER_CODES.each do |code|
      Rails.logger.info "Setting up ProviderUser uid: #{code}, email: provider-user-#{code}@example.com"

      create_provider_user({
        dfe_sign_in_uid: code,
        email_address: "provider-user-#{code}@example.com",
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
      }, [code])
    end
  end

  desc 'Set up support user'
  task setup_support_user: :environment do
    Rails.logger.info 'Setting up default SupportUser'

    SupportUser.create!(
      dfe_sign_in_uid: 'dev-support',
      email_address: 'support@example.com',
      first_name: 'Susan',
      last_name: 'Upport',
    )
  end
end

def create_provider_user(attrs, provider_codes)
  user = ProviderUser.create!(attrs)
  user.providers = Provider.where(code: provider_codes).all
  user.save!
end
