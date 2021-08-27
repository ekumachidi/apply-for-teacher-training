require 'rails_helper'

RSpec.describe ProviderInterface::ProviderPartnerPermissionBreakdownComponent do
  let(:provider) { create(:provider) }
  let(:permission) { :make_decisions }
  let(:render) { render_inline(described_class.new(provider: provider, permission: permission)) }

  def create_partner_provider_where(partner_provider_type:, permission_applies:, org_name: nil, course_open: true, relationship_set_up: true)
    my_provider_type = partner_provider_type == :training ? :ratifying : :training

    partner_provider = create(:provider, name: org_name || Faker::University.name)

    relationship_traits = relationship_set_up ? [] : %i[not_set_up_yet]

    relationship = create(
      :provider_relationship_permissions,
      *relationship_traits,
      "#{my_provider_type}_provider": provider,
      "#{partner_provider_type}_provider": partner_provider,
      "#{my_provider_type}_provider_can_#{permission}": permission_applies,
      "#{partner_provider_type}_provider_can_#{permission}": !permission_applies,
    )
    if course_open
      create(:course, :open_on_apply, provider: relationship.training_provider, accredited_provider: relationship.ratifying_provider)
    end

    partner_provider
  end

  context 'when there are partner organisations for which the permission applies' do
    let!(:ratifying_partners) { ['University of B', 'SCITT of Rock'].map { |name| create_partner_provider_where(partner_provider_type: :ratifying, org_name: name, permission_applies: true) } }
    let!(:training_partners) { ['University of A', 'SCITT of Destiny'].map { |name| create_partner_provider_where(partner_provider_type: :training, org_name: name, permission_applies: true) } }

    it 'renders the names of partner organisations for which the given provider has the permission' do
      expected_provider_names = (ratifying_partners + training_partners).map(&:name).sort
      expect(render.css('#partners-for-which-permission-applies li').map(&:text)).to eq(expected_provider_names)
    end

    it 'indicates that the permission applies to all partners' do
      expect(render.css('.govuk-body')[0].text)
        .to include('It currently applies to courses you work on with all of your partner organisations:')
    end

    context 'when there is a relationship without an open course' do
      let!(:no_course_partner) { create_partner_provider_where(partner_provider_type: :training, course_open: false, permission_applies: true) }

      it 'does not render the name of the partner with no open course' do
        expect(render.css('#partners-for-which-permission-applies li').map(&:text)).not_to include(no_course_partner.name)
      end
    end

    context 'when there are also partner organisations for which the permission does not apply' do
      before { create_partner_provider_where(partner_provider_type: :ratifying, permission_applies: false) }

      it 'does not indicate that the permission applies to all partners' do
        expect(render.css('.govuk-body')[0].text)
          .to include('It currently applies to courses you work on with:')
      end
    end
  end

  context 'when there are partner organisations for which the permission does not apply' do
    let!(:ratifying_partners) { ['University of X', 'School of Jazz'].map { |name| create_partner_provider_where(partner_provider_type: :ratifying, org_name: name, permission_applies: false) } }
    let!(:training_partners) { ['University of Z', 'Local school'].map { |name| create_partner_provider_where(partner_provider_type: :training, org_name: name, permission_applies: false) } }
    let!(:not_set_up_partners) { ['Not Setup College', 'School of Procrastination'].map { |name| create_partner_provider_where(partner_provider_type: :training, org_name: name, permission_applies: false, relationship_set_up: false) } }

    it 'renders the names of partner organisations for which the given provider does not have the permission' do
      expected_provider_names = (ratifying_partners + training_partners + not_set_up_partners).map(&:name).sort
      expect(render.css('#partners-for-which-permission-does-not-apply li').map(&:text)).to eq(expected_provider_names)
    end

    it 'indicates that the permission does not apply to any partners' do
      expect(render.css('.govuk-body')[0].text)
        .to include('It currently does not apply to courses you work on with any of your partner organisations:')
    end

    context 'when there is a relationship without an open course' do
      let!(:no_course_partner) { create_partner_provider_where(partner_provider_type: :training, course_open: false, permission_applies: false) }

      it 'does not render the name of the partner with no open course' do
        expect(render.css('#partners-for-which-permission-does-not-apply li').map(&:text)).not_to include(no_course_partner.name)
      end
    end

    context 'when there are also partner organisations for which the permission does apply' do
      before { create_partner_provider_where(partner_provider_type: :ratifying, permission_applies: true) }

      it 'does not indicate that the permission does not apply to any partners' do
        expect(render.css('.govuk-body')[1].text)
          .to include('It currently does not apply to courses you work on with:')
      end
    end
  end
end
