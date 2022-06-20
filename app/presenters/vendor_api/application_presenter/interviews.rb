module VendorAPI::ApplicationPresenter::Interviews
  def schema
    super.deep_merge!({
      attributes: {
        interviews: interviews.map { |interview| VendorAPI::InterviewPresenter.new(active_version, interview).schema },
      },
    })
  end

  def interviews
    application_choice.interviews.sort(&:updated_at).reverse
  end
end
