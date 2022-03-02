require 'rails_helper'

RSpec.describe ProviderInterface::RejectionReasonsWizard do
  let(:attrs) { { current_step: 'edit' } }
  let(:store) { instance_double(WizardStateStores::RedisStore) }

  before { allow(store).to receive(:read) }

  subject(:instance) { described_class.new(store, attrs) }

  describe '.rejection_reasons' do
    it 'builds rejection reasons from configuration' do
      rejection_reasons = described_class.rejection_reasons
      expect(rejection_reasons).to be_a(RejectionReasons)
      expect(rejection_reasons.reasons.first).to be_a(RejectionReasons::Reason)
      expect(rejection_reasons.reasons.first.reasons.first).to be_a(RejectionReasons::Reason)
      expect(rejection_reasons.reasons.last.details).to be_a(RejectionReasons::Details)
    end
  end

  describe 'dynamic attributes' do
    it 'defines accessors for all attributes' do
      described_class.attribute_names.each do |attr_name|
        expect(instance.respond_to?(attr_name)).to be(true)
        expect(instance.respond_to?("#{attr_name}=")).to be(true)
      end
    end
  end
end
