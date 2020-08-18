require 'rails_helper'

RSpec.describe Candidate, type: :model do
  describe 'a valid candidate' do
    subject { create(:candidate) }

    it { is_expected.to validate_presence_of :email_address }
    it { is_expected.to validate_length_of(:email_address).is_at_most(100) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
    it { is_expected.to allow_value('user@example.com').for(:email_address) }
    it { is_expected.not_to allow_value('foo').for(:email_address) }
    it { is_expected.not_to allow_value(Faker::Lorem.characters(number: 251)).for(:email_address) }
  end

  describe '#delete' do
    it 'deletes all dependent records through cascading deletes in the database' do
      candidate = create(:candidate)
      application_form = create(:application_form, candidate: candidate)
      application_choice = create(:application_choice, application_form: application_form)
      application_work_experience = create(:application_work_experience, application_form: application_form)
      application_volunteering_experience = create(:application_volunteering_experience, application_form: application_form)
      application_qualification = create(:application_qualification, application_form: application_form)
      application_reference = create(:reference, application_form: application_form)

      candidate.delete

      expect { candidate.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_form.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_choice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_work_experience.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_volunteering_experience.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_qualification.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#current_application' do
    it 'returns an existing application_form' do
      candidate = create(:candidate)
      application_form = create(:application_form, candidate: candidate)

      expect(candidate.current_application).to eq(application_form)
    end

    it 'creates an application_form if there are none' do
      candidate = create(:candidate)

      expect { candidate.current_application }.to change { candidate.application_forms.count }.from(0).to(1)
    end
  end

  describe 'find_from_course' do
    it 'returns the correct course' do
      course = create(:course)
      candidate = create(:candidate, course_from_find_id: course.id)

      expect(candidate.course_from_find).to eq(course)
    end

    it 'returns nil if there is no course_from_find_id' do
      candidate = create(:candidate)

      expect(candidate.course_from_find).to eq(nil)
    end
  end

  describe '#refresh_magic_link_token!' do
    let(:candidate) { create(:candidate) }
    let(:magic_link_token) do
      instance_double(
        MagicLinkToken, raw: 'RAW', encrypted: 'ENCRYPTED'
      )
    end

    before do
      allow(MagicLinkToken).to receive(:new).and_return(magic_link_token)
    end

    it 'persists the encrypted token and refresh time' do
      Timecop.freeze(Time.zone.local(1955, 11, 5)) do
        candidate.refresh_magic_link_token!

        expect(candidate.magic_link_token).to eq 'ENCRYPTED'
        expect(candidate.magic_link_token_sent_at).to eq Time.zone.local(1955, 11, 5)
      end
    end

    it 'returns the raw token' do
      expect(candidate.refresh_magic_link_token!).to eq 'RAW'
    end
  end

  describe '#encrypted_id' do
    let(:candidate) { create(:candidate) }

    it 'invokes Encryptor to encrypt id' do
      allow(Encryptor).to receive(:encrypt).with(candidate.id).and_return 'encrypted id value'

      expect(candidate.encrypted_id).to eq 'encrypted id value'
    end
  end

  describe '#update_sign_in_fields!' do
    it 'clears the magic link fields and sets last_signed_in_at' do
      Timecop.freeze(Time.zone.local(0)) do
        candidate = create(:candidate, magic_link_token: 'token', magic_link_token_sent_at: Time.zone.now)
        candidate.update_sign_in_fields!

        expect(candidate.magic_link_token).to be_nil
        expect(candidate.magic_link_token_sent_at).to be_nil
        expect(candidate.last_signed_in_at).to eq Time.zone.local(0)
      end
    end
  end
end
