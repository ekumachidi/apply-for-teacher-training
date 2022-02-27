module Publications
  class MonthlyStatisticsController < ApplicationController
    before_action :redirect_unless_published
    rescue_from ActiveRecord::RecordNotFound, with: :render_404

    def show
      @presenter = Publications::MonthlyStatisticsPresenter.new(current_report)

      @csv_export_types_and_sizes = calculate_download_sizes(current_report)
      @academic_year_name = RecruitmentCycle.cycle_name(CycleTimetable.next_year)
      @current_cycle_name = RecruitmentCycle.verbose_cycle_name
    end

    def download
      export_type = params[:export_type]
      export_filename = "#{export_type}-#{params[:month]}.csv"
      raw_data = current_report.statistics[export_type]
      header_row = raw_data['rows'].first.keys
      data = SafeCSV.generate(raw_data['rows'].map(&:values), header_row)
      send_data data, filename: export_filename, disposition: :attachment
    end

    def redirect_unless_published
      redirect_to root_path unless FeatureFlag.active?(:publish_monthly_statistics)
    end

    def calculate_download_sizes(report)
      report.statistics.map do |k, raw_data|
        next unless raw_data.is_a?(Hash)

        header_row = raw_data['rows'].first.keys
        data = SafeCSV.generate(raw_data['rows'].map(&:values), header_row)
        [k, data.size]
      end.compact
    end

  private

    def current_report
      if params[:month].present?
        MonthlyStatisticsTimetable.report_for(params[:month])
      elsif FeatureFlag.active? :lock_external_report_to_january_2022
        MonthlyStatisticsTimetable.report_for('2022-01')
      else
        MonthlyStatisticsTimetable.report_for_current_period
      end
    end
  end
end
