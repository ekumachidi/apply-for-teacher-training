require 'rails_helper'

RSpec.describe ApplicationForm do
  it 'sets a support reference upon creation' do
    application_form = create :application_form
    expect(application_form.support_reference).to be_present
  end

  describe '#previous_application_form' do
    it 'refers to the previous application' do
      previous_application_form = create(:application_form)
      application_form = create(:application_form, previous_application_form_id: previous_application_form.id)

      expect(application_form.previous_application_form).to eql(previous_application_form)
      expect(application_form.previous_application_form.subsequent_application_form).to eql(application_form)
    end
  end

  describe '#choices_left_to_make' do
    it 'returns the number of choices that an candidate can make in the first instance' do
      application_form = create(:application_form)

      expect(application_form.reload.choices_left_to_make).to be(3)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(2)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(1)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(0)
    end

    it 'returns the number of choices that an candidate can make in "Apply 2"' do
      application_form = create(:application_form, phase: 'apply_2')

      expect(application_form.reload.choices_left_to_make).to be(1)

      create(:application_choice, application_form: application_form)

      expect(application_form.reload.choices_left_to_make).to be(0)
    end
  end

  describe 'auditing', with_audited: true do
    it 'records an audit entry when creating a new ApplicationForm' do
      application_form = create :application_form
      expect(application_form.audits.count).to eq 1
    end

    it 'can view audit records for ApplicationForm and its associated ApplicationChoices' do
      application_form = create(:completed_application_form, application_choices_count: 1)

      expect {
        application_form.application_choices.first.update!(rejection_reason: 'rejected')
      }.to change { application_form.own_and_associated_audits.count }.by(1)
    end
  end

  describe '#science_gcse_needed?' do
    context 'when a candidate has no course choices' do
      it 'returns false' do
        application_form = build_stubbed(:application_form)

        expect(application_form.science_gcse_needed?).to eq(false)
      end
    end

    context 'when a candidate has a course choice that is primary' do
      it 'returns true' do
        application_form = application_form_with_course_option_for_provider_with(level: 'primary')

        expect(application_form.science_gcse_needed?).to eq(true)
      end
    end

    context 'when a candidate has a course choice that is secondary' do
      it 'returns false' do
        application_form = application_form_with_course_option_for_provider_with(level: 'secondary')

        expect(application_form.science_gcse_needed?).to eq(false)
      end
    end

    context 'when a candidate has a course choice that is further education' do
      it 'returns false' do
        application_form = application_form_with_course_option_for_provider_with(level: 'further_education')

        expect(application_form.science_gcse_needed?).to eq(false)
      end
    end

    def application_form_with_course_option_for_provider_with(level:)
      provider = build(:provider)
      course = create(:course, level: level, provider: provider)
      site = create(:site, provider: provider)
      course_option = create(:course_option, course: course, site: site)
      application_form = create(:application_form)

      create(
        :application_choice,
        application_form: application_form,
        course_option: course_option,
      )

      application_form
    end
  end

  describe '#blank_application?' do
    context 'when a candidate has not made any alterations to their applicaiton' do
      it 'returns true' do
        application_form = create(:application_form)
        expect(application_form.blank_application?).to be_truthy
      end
    end

    context 'when a candidate has amended their application' do
      it 'returns false' do
        application_form = create(:application_form)
        create(:application_work_experience, application_form: application_form)
        expect(application_form.blank_application?).to be_falsey
      end
    end
  end

  describe '#ended_without_success?' do
    context 'with one rejected application' do
      it 'returns true' do
        application_form = described_class.new
        application_form.application_choices.build status: 'rejected'
        expect(application_form.ended_without_success?).to be true
      end
    end

    context 'with one offered application' do
      it 'returns false' do
        application_form = described_class.new
        application_form.application_choices.build status: 'offer'
        expect(application_form.ended_without_success?).to be false
      end
    end

    context 'with one rejected and one in progress application' do
      it 'returns false' do
        application_form = described_class.new
        application_form.application_choices.build status: 'rejected'
        application_form.application_choices.build status: 'awaiting_provider_decision'
        expect(application_form.ended_without_success?).to be false
      end
    end

    context 'with one rejected and one withdrawn application' do
      it 'returns true' do
        application_form = described_class.new
        application_form.application_choices.build status: 'rejected'
        application_form.application_choices.build status: 'withdrawn'
        expect(application_form.ended_without_success?).to be true
      end
    end
  end

  describe '#can_add_reference?' do
    it 'returns true if there are fewer than 2 references' do
      application_reference = build :reference
      application_form = build :application_form, application_references: [application_reference]
      expect(application_form.can_add_reference?).to be true
    end

    it 'returns false if there are already 2 references' do
      application_reference1 = build :reference
      application_reference2 = build :reference
      application_form = build(
        :application_form,
        application_references: [application_reference1, application_reference2],
      )
      expect(application_form.can_add_reference?).to be false
    end
  end

  describe '#equality_and_diversity_answers_provided?' do
    context 'when minimal expected attributes are present' do
      it 'is true' do
        application_form = build(:completed_application_form, :with_equality_and_diversity_data)
        expect(application_form.equality_and_diversity_answers_provided?).to be true
      end
    end

    context 'when minimal expected attributes are not present' do
      it 'is false' do
        application_form = build(:completed_application_form)
        application_form.equality_and_diversity = { 'sex' => 'male' }

        expect(application_form.equality_and_diversity_answers_provided?).to be false
      end
    end

    context 'when no attributes are present' do
      it 'is false' do
        application_form = build(:completed_application_form)
        application_form.equality_and_diversity = nil

        expect(application_form.equality_and_diversity_answers_provided?).to be false
      end
    end
  end

  describe '#course_choices_that_need_replacing' do
    it 'returns course_choices that are not on apply, whose courses have been withdrawn or course_option has become full' do
      application_form = create(:application_form)
      course1 = create(:course, withdrawn: true, open_on_apply: true)
      course2 = create(:course, withdrawn: false, open_on_apply: true)
      course3 = create(:course, withdrawn: false, open_on_apply: true)
      course4 = create(:course, withdrawn: false, open_on_apply: false)

      course_option1 = create(:course_option, course: course1, vacancy_status: 'no_vacancies')
      course_option2 = create(:course_option, course: course2, vacancy_status: 'no_vacancies')
      course_option3 = create(:course_option, course: course3, vacancy_status: 'vacancies')
      course_option4 = create(:course_option, course: course4, vacancy_status: 'vacancies')

      application_choice1 = create(:application_choice, status: :awaiting_references, application_form: application_form, course_option: course_option1)
      application_choice2 = create(:application_choice, status: :awaiting_references, application_form: application_form, course_option: course_option2)
      create(:application_choice, application_form: application_form, course_option: course_option3)
      application_choice4 = create(:application_choice, status: :awaiting_references, application_form: application_form, course_option: course_option4)

      expect(application_form.course_choices_that_need_replacing).to match_array [application_choice1, application_choice2, application_choice4]
    end
  end

  describe '#english_speaking_nationality?' do
    context 'when any applicant nationality is identified as "English-speaking"' do
      let(:nationality_permutations) do
        [
          { first_nationality: 'British', second_nationality: 'Pakistani' },
          { first_nationality: 'Pakistani', second_nationality: 'British' },
          { first_nationality: 'British', second_nationality: nil },
          { first_nationality: 'Irish', second_nationality: 'Pakistani' },
          { first_nationality: 'Pakistani', second_nationality: 'Irish' },
          { first_nationality: 'Irish', second_nationality: nil },
          { first_nationality: 'Iranian', second_nationality: 'Pakistani', third_nationality: 'Irish' },
        ]
      end

      it 'returns true' do
        nationality_permutations.each do |permutation|
          application_form = build(:application_form, permutation)
          expect(application_form.english_speaking_nationality?).to eq true
        end
      end
    end

    context 'when no applicant nationality is identified as "English-speaking"' do
      let(:nationality_permutations) do
        [
          { first_nationality: 'Pakistani', second_nationality: nil },
          { first_nationality: 'Chinese', second_nationality: 'Pakistani' },
          { first_nationality: 'Chinese', second_nationality: 'Pakistani', third_nationality: 'Jamaican' },
        ]
      end

      it 'return false' do
        nationality_permutations.each do |permutation|
          application_form = build(:application_form, permutation)
          expect(application_form.english_speaking_nationality?).to eq false
        end
      end
    end
  end

  describe '#nationalities' do
    it 'returns the candidates nationalities in an array' do
      application_form = build_stubbed(:application_form,
                                       first_nationality: 'British',
                                       second_nationality: 'Irish',
                                       third_nationality: 'Welsh',
                                       fourth_nationality: 'Northern Irish',
                                       fifth_nationality: nil)

      expect(application_form.nationalities).to match_array ['British', 'Irish', 'Welsh', 'Northern Irish']
    end
  end

  describe '#english_main_language' do
    context 'when fetch_database_value is set to true' do
      it 'returns whatever is in the database field' do
        [nil, true, false].each do |db_value|
          application_form = build(:application_form, english_main_language: db_value)
          expect(
            application_form.english_main_language(fetch_database_value: true),
          ).to eq db_value
        end
      end
    end

    context 'database value is nil' do
      let(:application_form) { build(:application_form, english_main_language: nil) }

      it 'returns false by default' do
        expect(application_form.english_main_language).to eq false
      end

      context 'when english_speaking_nationality? is true' do
        it 'returns true' do
          application_form.first_nationality = 'British'

          expect(application_form.english_main_language).to eq true
        end
      end

      context 'when the english_proficiency record declares that a qualification is not needed' do
        it 'returns true' do
          english_proficiency = build(:english_proficiency, :qualification_not_needed)
          application_form.english_proficiency = english_proficiency

          expect(application_form.english_main_language).to eq true
        end
      end
    end

    context 'database value is true' do
      let(:application_form) { build(:application_form, english_main_language: true) }

      it 'returns true' do
        expect(application_form.english_main_language).to eq true
      end
    end

    context 'database value is false' do
      let(:application_form) { build(:application_form, english_main_language: false) }

      it 'returns false' do
        expect(application_form.english_main_language).to eq false
      end
    end
  end

  describe '#efl_section_required?' do
    let(:application_with_english_speaking_nationality) do
      build_stubbed :application_form, first_nationality: 'British', second_nationality: 'French'
    end

    let(:application_with_no_english_speaking_nationalities) do
      build_stubbed :application_form, first_nationality: 'Jamaican', second_nationality: 'Chinese'
    end

    context 'efl_section feature flag is off' do
      before { FeatureFlag.deactivate :efl_section }

      it 'returns false' do
        expect(application_with_english_speaking_nationality.efl_section_required?).to be false
        expect(application_with_no_english_speaking_nationalities.efl_section_required?).to be false
      end
    end

    context 'efl_section feature flag is on' do
      before { FeatureFlag.activate :efl_section }

      context 'at least one selected nationality is considered "English-speaking"' do
        let(:application_form) { application_with_english_speaking_nationality }

        it 'returns false' do
          expect(application_form.efl_section_required?).to be false
        end
      end

      context 'no "English-speaking" nationalities selected' do
        let(:application_form) { application_with_no_english_speaking_nationalities }

        it 'returns true' do
          expect(application_form.efl_section_required?).to be true
        end
      end

      context 'nationalities not selected' do
        let(:application_form) { build_stubbed :application_form }

        it 'returns false' do
          expect(application_form.efl_section_required?).to be false
        end
      end
    end
  end

  describe '#all_applications_not_sent?' do
    let(:application_form) { build(:application_form) }

    it 'returns true if all application choices are in the application_not_sent or withdrawn state' do
      create(:application_choice, :application_not_sent, application_form: application_form)
      create(:application_choice, :withdrawn, application_form: application_form)

      expect(application_form.all_applications_not_sent?).to eq true
    end

    it 'returns false if application choices are in any other state' do
      create(:application_choice, :withdrawn, application_form: application_form)

      expect(application_form.all_applications_not_sent?).to eq false
    end
  end

  describe '#has_rejection_reason?' do
    let(:application_form) { create(:completed_application_form) }

    it 'returns true if any of the choices are rejected' do
      create(:application_choice, :with_rejection, application_form: application_form)

      expect(application_form.has_rejection_reason?).to eq true
    end
  end

  describe '#references_did_not_come_back_in_time?' do
    let(:application_form) { create(:completed_application_form) }

    it 'returns true if all references were cancelled at end of cycle' do
      create(:reference, application_form: application_form, feedback_status: :cancelled_at_end_of_cycle)

      expect(application_form.references_did_not_come_back_in_time?).to eq true
    end
  end
end
