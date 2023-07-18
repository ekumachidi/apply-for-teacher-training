require 'rails_helper'

RSpec.describe DeleteProvider, type: :model do
  let(:service) { described_class.new(provider_id: provider.id) }

  let(:application_form) do
    create(:application_form, :completed,
           application_choices_count: 1,
           submitted_application_choices_count: 1)
  end
  let(:provider) { application_form.application_choices.first.provider }

  it 'has a provider' do
    expect { service.call! }.to change { Provider.exists?(provider.id) }.from(true).to(false)
  end
end
