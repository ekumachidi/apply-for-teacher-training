require 'rails_helper'

RSpec.describe Provider, type: :model do
  describe '#onboarded?' do
    it 'depends on the presence of a signed Data sharing agreement' do
      provider_with_dsa = create(:provider, :with_signed_agreement)
      provider_without_dsa = create(:provider)

      expect(provider_with_dsa).to be_onboarded
      expect(provider_without_dsa).not_to be_onboarded
    end
  end

  describe '#all_associated_accredited_providers_onboarded?' do
    let(:provider) { create(:provider) }

    subject(:result) { provider.all_associated_accredited_providers_onboarded? }

    it 'returns true when the accredited bodies are all onboarded' do
      create(:course, provider: provider, accredited_provider: create(:provider, :with_signed_agreement))

      expect(result).to be true
    end

    it 'returns false when some accredited bodies are onboarded' do
      create(:course, provider: provider, accredited_provider: create(:provider, :with_signed_agreement))
      create(:course, provider: provider, accredited_provider: create(:provider))

      expect(result).to be false
    end

    it 'returns false when there are no accredited bodies' do
      create(:course, provider: provider, accredited_provider: create(:provider))

      expect(result).to be false
    end
  end
end
