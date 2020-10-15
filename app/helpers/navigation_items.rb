class NavigationItems
  NavigationItem = Struct.new(:text, :href, :active)

  class << self
    include Rails.application.routes.url_helpers
    include AbstractController::Translation

    def for_candidate_interface(current_candidate, _current_controller)
      if current_candidate
        [
          NavigationItem.new(current_candidate.email_address, nil, false),
          NavigationItem.new('Sign out', candidate_interface_sign_out_path, false),
        ]
      else
        [
          NavigationItem.new('Sign in', candidate_interface_sign_in_path, false),
        ]
      end
    end

    def for_support_primary_nav(current_support_user, current_controller)
      if current_support_user
        [
          NavigationItem.new('Candidates', support_interface_applications_path, is_active(current_controller, %w[candidates change_course import_references application_forms ucas_matches])),
          NavigationItem.new('Providers', support_interface_providers_path, is_active(current_controller, %w[providers courses provider_users api_tokens])),
          NavigationItem.new('Performance', support_interface_performance_path, is_active(current_controller, %w[performance data_exports course_options email_log validation_errors])),
          NavigationItem.new('Settings', support_interface_feature_flags_path, is_active(current_controller, %w[feature_flags cycles support_users tasks])),
          NavigationItem.new('Documentation', support_interface_docs_path, is_active(current_controller, %w[docs])),
        ]
      else
        []
      end
    end

    def for_support_account_nav(current_support_user)
      if current_support_user
        [
          NavigationItem.new(current_support_user.email_address, nil, false),
          NavigationItem.new('Sign out', support_interface_sign_out_path, false),
        ]
      else
        [
          NavigationItem.new('Sign in', support_interface_sign_in_path, false),
        ]
      end
    end

    def for_provider_primary_nav(current_provider_user, current_controller, performing_setup = false)
      items = []

      if current_provider_user && !performing_setup
        items << NavigationItem.new('Applications', provider_interface_applications_path, is_active(current_controller, %w[application_choices decisions offer_changes]))

        if FeatureFlag.active?(:export_hesa_data)
          items << NavigationItem.new('Export data', provider_interface_new_applications_export_path, is_active(current_controller, %w[applications_exports]))
        end
      end

      items
    end

    def for_provider_account_nav(current_provider_user, current_controller, performing_setup = false)
      return [NavigationItem.new('Sign in', provider_interface_sign_in_path, false)] unless current_provider_user

      items = []

      unless performing_setup
        if current_provider_user.authorisation.can_manage_organisations_for_at_least_one_provider?
          items << NavigationItem.new('Organisations', provider_interface_organisations_path, is_active(current_controller, %w[organisations provider_relationship_permissions]))
        end

        if current_provider_user.authorisation.can_manage_users_for_at_least_one_provider?
          items << NavigationItem.new('Users', provider_interface_provider_users_path, is_active(current_controller, 'provider_users'))
        end

        items << NavigationItem.new('Account', provider_interface_account_path, is_active(current_controller, 'account'))
      end

      items << NavigationItem.new('Sign out', provider_interface_sign_out_path, false)
    end

    def for_api_docs(current_controller)
      [
        NavigationItem.new('Home', api_docs_home_path, is_active_action(current_controller, 'home')),
        NavigationItem.new(t('page_titles.api_docs.usage'), api_docs_usage_path, is_active_action(current_controller, 'usage')),
        NavigationItem.new(t('page_titles.api_docs.reference'), api_docs_reference_path, is_active_action(current_controller, 'reference')),
        NavigationItem.new(t('page_titles.api_docs.release_notes'), api_docs_release_notes_path, is_active_action(current_controller, 'release_notes')),
        NavigationItem.new(t('page_titles.api_docs.lifecycle'), api_docs_lifecycle_path, is_active_action(current_controller, 'lifecycle')),
        NavigationItem.new(t('page_titles.api_docs.help'), api_docs_help_path, is_active_action(current_controller, 'help')),
      ]
    end

  private

    def is_active(current_controller, active_controllers)
      current_controller.controller_name.in?(Array.wrap(active_controllers))
    end

    def is_active_action(current_controller, active_action)
      current_controller.action_name == active_action
    end
  end
end
