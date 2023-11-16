module ProviderInterface
  class SortApplicationChoices
    RBD_FEEDBACK_LAUNCH_TIMESTAMP = '\'2020-11-17T00:00:00+00:00\'::TIMESTAMPTZ'.freeze

    extend ApplicationHelper

    def self.call(application_choices:)
      for_task_view(application_choices).order(sort_order)
    end

    def self.for_task_view(application_choices)
      application_choices.from <<~WITH_TASK_VIEW_GROUP.squish
        (
          SELECT a.*,
            CASE
              WHEN #{inactive} THEN 1
              WHEN #{awaiting_provider_decision} THEN 2
              WHEN #{deferred_offers_pending_reconfirmation} THEN 3
              WHEN #{give_feedback_for_rbd} THEN 4
              WHEN #{interviewing} THEN 5
              WHEN #{pending_conditions_previous_cycle} THEN 6
              WHEN #{waiting_on_candidate} THEN 7
              WHEN #{pending_conditions_current_cycle} THEN 8
              WHEN #{successful_candidates} THEN 9
              WHEN #{deferred_offers_current_cycle} THEN 10
              ELSE 999
            END AS task_view_group

            FROM application_choices a
        ) AS application_choices
      WITH_TASK_VIEW_GROUP
    end

    def self.deferred_offers_pending_reconfirmation
      <<~DEFERRED_OFFERS_PENDING_RECONFIRMATION.squish
        (
          status = 'offer_deferred'
            AND current_recruitment_cycle_year = #{RecruitmentCycle.previous_year}
        )
      DEFERRED_OFFERS_PENDING_RECONFIRMATION
    end

    def self.pending_conditions_previous_cycle
      <<~PREVIOUS_CYCLE_PENDING_CONDITIONS.squish
        (
          status = 'pending_conditions'
            AND current_recruitment_cycle_year = #{RecruitmentCycle.previous_year}
        )
      PREVIOUS_CYCLE_PENDING_CONDITIONS
    end

    def self.give_feedback_for_rbd
      <<~GIVE_FEEDBACK_FOR_RBD.squish
        (
          status = 'rejected'
            AND rejected_by_default
            AND rejection_reason IS NULL
            AND structured_rejection_reasons IS NULL
            AND rejected_at >= #{RBD_FEEDBACK_LAUNCH_TIMESTAMP}
        )
      GIVE_FEEDBACK_FOR_RBD
    end

    def self.awaiting_provider_decision
      <<~AWAITING_PROVIDER_DECISION.squish
        (status = 'awaiting_provider_decision')
      AWAITING_PROVIDER_DECISION
    end

    def self.inactive
      <<~INACTIVE.squish
        (status = 'inactive')
      INACTIVE
    end

    def self.interviewing
      <<~INTERVIEWING.squish
        (status = 'interviewing')
      INTERVIEWING
    end

    def self.waiting_on_candidate
      <<~WAITING_ON_CANDIDATE.squish
        (
          status = 'offer'
            AND current_recruitment_cycle_year = #{RecruitmentCycle.current_year}
        )
      WAITING_ON_CANDIDATE
    end

    def self.pending_conditions_current_cycle
      <<~CURRENT_CYCLE_PENDING_CONDITIONS.squish
        (
          status = 'pending_conditions'
            AND current_recruitment_cycle_year = #{RecruitmentCycle.current_year}
        )
      CURRENT_CYCLE_PENDING_CONDITIONS
    end

    def self.successful_candidates
      <<~SUCCESSFUL_CANDIDATES.squish
        (
          status = 'recruited'
            AND current_recruitment_cycle_year = #{RecruitmentCycle.current_year}
        )
      SUCCESSFUL_CANDIDATES
    end

    def self.deferred_offers_current_cycle
      <<~DEFERRED_OFFERS_CURRENT_CYCLE.squish
        (
          status = 'offer_deferred'
            AND current_recruitment_cycle_year = #{RecruitmentCycle.current_year}
        )
      DEFERRED_OFFERS_CURRENT_CYCLE
    end

    def self.sort_order
      <<~ORDER_BY.squish
        task_view_group,
        application_choices.updated_at DESC
      ORDER_BY
    end
  end
end
