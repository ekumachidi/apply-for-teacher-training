module SupportInterface
  class BlockSubmissionForm
    include ActiveModel::Model

    attr_accessor :accept_guidance

    validates :accept_guidance, presence: true

    def save(fraud_match_id)
      self.accept_guidance = ActiveModel::Type::Boolean.new.cast(accept_guidance)

      return false unless valid?

      DuplicateMatch.find(fraud_match_id).candidates.each do |candidate|
        return false unless candidate.update(submission_blocked: true)
      end

      true
    end
  end
end
