module Publications
  module MonthlyStatistics
    class ByAgeGroup < Publications::MonthlyStatistics::Base
      def table_data
        {
          rows: apply_minimum_value_rule_to_rows(rows),
          column_totals: apply_minimum_value_rule_to_totals(column_totals_for(rows)),
        }
      end

    private

      def rows
        @rows ||= formatted_age_group_query.map do |age_group, statuses|
          {
            'Age group' => age_group,
            'Recruited' => recruited_count(statuses),
            'Conditions pending' => pending_count(statuses),
            'Received an offer' => offer_count(statuses),
            'Awaiting provider decisions' => awaiting_decision_count(statuses),
            'Unsuccessful' => unsuccessful_count(statuses),
            'Total' => statuses_count(statuses),
          }
        end
      end

      def column_totals_for(rows)
        _age_group, *statuses = rows.first.keys

        statuses.map do |column_name|
          column_total = rows.inject(0) { |total, hash| total + hash[column_name] }
          column_total
        end
      end

      def formatted_age_group_query
        counts = {
          '21 and under' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '22' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '23' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '24' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '25 to 29' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '30 to 34' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '35 to 39' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '40 to 44' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '45 to 49' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '50 to 54' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '55 to 59' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '60 to 64' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
          '65 and over' => {
            'recruited' => 0,
            'pending_conditions' => 0,
            'offer' => 0,
            'awaiting_provider_decision' => 0,
            'ended_without_success' => 0,
            'total' => 0,
          },
        }

        age_group_counts.map do |item|
          age_group = item['age_group']
          status = item['status']
          count = item['count']

          counts[age_group].merge!({ status => count })
        end

        deferred_offers_count.map do |item|
          age_group = item['age_group']
          status_before_deferral = item['status_before_deferral']
          count = item['count']
          counts[age_group][status_before_deferral] += count
        end

        counts
      end

      def age_group_counts
        @age_group_counts ||= ActiveRecord::Base
          .connection
          .execute(age_group_query)
          .to_a
          .reject { |row| row.values.include?('offer_deferred') }
      end

      def age_group_query
        <<-SQL
          WITH raw_data AS (
              SELECT
                  c.id,
                  f.id,
                  CASE
                    WHEN 'recruited' = ANY(ARRAY_AGG(ch.status)) THEN 'recruited'
                    WHEN 'offer_deferred' = ANY(ARRAY_AGG(ch.status)) THEN 'offer_deferred'
                    WHEN 'pending_conditions' = ANY(ARRAY_AGG(ch.status)) THEN 'pending_conditions'
                    WHEN 'offer' = ANY(ARRAY_AGG(ch.status)) THEN 'offer'
                    WHEN 'awaiting_provider_decision' = ANY(ARRAY_AGG(ch.status)) THEN 'awaiting_provider_decision'
                    WHEN 'declined' = ANY(ARRAY_AGG(ch.status)) THEN 'declined'
                    WHEN 'rejected' = ANY(ARRAY_AGG(ch.status)) THEN 'rejected'
                    WHEN 'conditions_not_met' = ANY(ARRAY_AGG(ch.status)) THEN 'conditions_not_met'
                    WHEN 'offer_withdrawn' = ANY(ARRAY_AGG(ch.status)) THEN 'offer_withdrawn'
                    WHEN 'withdrawn' = ANY(ARRAY_AGG(ch.status)) THEN 'withdrawn'
                  END status,
                  CASE
                    #{age_group_sql}
                  END age_group
              FROM
                  application_forms f
              LEFT JOIN
                  candidates c ON f.candidate_id = c.id
              LEFT JOIN
                  application_choices ch ON ch.application_form_id = f.id
              WHERE
                  NOT c.hide_in_reporting
                  AND f.recruitment_cycle_year = #{RecruitmentCycle.current_year}
                  AND f.date_of_birth IS NOT NULL
                  AND (
                    NOT EXISTS (
                      SELECT 1
                      FROM application_forms
                      AS subsequent_application_forms
                      WHERE f.id = subsequent_application_forms.previous_application_form_id
                    )
                  )
              GROUP BY
                  c.id, f.id, age_group
          )
          SELECT
              raw_data.status,
              raw_data.age_group,
              COUNT(*)
          FROM
              raw_data
          GROUP BY
              raw_data.status, raw_data.age_group
          ORDER BY
              raw_data.status
        SQL
      end

      def deferred_offers_count
        @deferred_offers_counts ||= ActiveRecord::Base
          .connection
          .execute(deferred_offers_query)
          .to_a
      end

      def deferred_offers_query
        <<-SQL
          WITH raw_data AS (
              SELECT
                  c.id,
                  f.id,
                  ch.status_before_deferral,
                  CASE
                    #{age_group_sql}
                  END age_group
              FROM
                  application_forms f
              LEFT JOIN
                  candidates c ON f.candidate_id = c.id
              LEFT JOIN
                  application_choices ch ON ch.application_form_id = f.id
              WHERE
                  NOT c.hide_in_reporting
                  AND f.recruitment_cycle_year = #{RecruitmentCycle.previous_year}
                  AND f.date_of_birth IS NOT NULL
                  AND ch.status_before_deferral IS NOT NULL
              GROUP BY
                  c.id, f.id, age_group, status_before_deferral
          )
          SELECT
              raw_data.status_before_deferral,
              raw_data.age_group,
              COUNT(*)
          FROM
              raw_data
          GROUP BY
              raw_data.status_before_deferral, raw_data.age_group
          ORDER BY
              raw_data.status_before_deferral
        SQL
      end

      def age_group_sql
        "WHEN f.date_of_birth > '#{Date.new(RecruitmentCycle.current_year - 22, 7, 31)}' THEN '21 and under'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 23, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 22, 7, 31)}' THEN '22'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 24, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 23, 7, 31)}' THEN '23'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 25, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 24, 7, 31)}' THEN '24'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 30, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 25, 7, 31)}' THEN '25 to 29'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 35, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 30, 7, 31)}' THEN '30 to 34'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 40, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 35, 7, 31)}' THEN '35 to 39'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 45, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 40, 7, 31)}' THEN '40 to 44'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 50, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 45, 7, 31)}' THEN '45 to 49'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 55, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 50, 7, 31)}' THEN '50 to 54'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 60, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 55, 7, 31)}' THEN '55 to 59'
        WHEN f.date_of_birth BETWEEN '#{Date.new(RecruitmentCycle.current_year - 65, 8, 1)}' AND '#{Date.new(RecruitmentCycle.current_year - 60, 7, 31)}' THEN '60 to 64'
        WHEN f.date_of_birth < '#{Date.new(RecruitmentCycle.current_year - 65, 8, 1)}' THEN '65 and over'"
      end
    end
  end
end