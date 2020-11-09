require 'rails_helper'

RSpec.describe CandidateInterface::ScienceGcseGradeForm, type: :model do
  describe 'validations' do
    before { FeatureFlag.deactivate(:international_gcses) }

    it { is_expected.to validate_length_of(:grade).is_at_most(6) }

    context 'when grade is "other"' do
      let(:form) { subject }

      before { allow(form).to receive(:grade_is_other?).and_return(true) }

      it { is_expected.to validate_presence_of(:other_grade) }
    end

    context 'when qualification type is GCSE' do
      context 'single award' do
        let(:qualification) do
          FactoryBot.build_stubbed(
            :application_qualification,
            subject: 'science single award',
            qualification_type: 'gcse',
            level: 'gcse',
          )
        end
        let(:form) { CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification) }

        it 'returns no errors if grade is valid' do
          mistyped_grades = %w[a b c]
          valid_grades = SINGLE_GCSE_GRADES + mistyped_grades

          valid_grades.each do |grade|
            form.grade = grade
            form.validate

            expect(form.errors[:single_award_grade]).to be_empty
          end
        end

        it 'returns validation error if grade is blank' do
          form.validate

          expect(form.errors[:single_award_grade]).to include('Enter your science single award grade')
        end

        it 'return validation error if grade is invalid' do
          invalid_grades = %w[012 XYZ T 54%]

          invalid_grades.each do |grade|
            form.grade = grade
            form.validate

            expect(form.errors[:single_award_grade]).to include('Enter a real science single award grade')
          end
        end

        it 'logs validation errors if grade is invalid' do
          allow(Rails.logger).to receive(:info)
          form.grade = 'XYZ'

          form.save

          expect(Rails.logger).to have_received(:info).with(
            'Validation error: {:field=>"single_award_grade", :error_messages=>"Enter a real science single award grade", :value=>"XYZ"}',
          )
        end
      end

      context 'double award' do
        let(:qualification) do
          FactoryBot.build_stubbed(
            :application_qualification,
            subject: 'science double award',
            qualification_type: 'gcse',
            level: 'gcse',
          )
        end
        let(:form) { CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification) }

        it 'returns no errors if grade is valid' do
          mistyped_grades = ['A a', 'A    a', 'b b']
          valid_grades = DOUBLE_GCSE_GRADES + mistyped_grades

          valid_grades.each do |grade|
            form.grade = grade
            form.validate

            expect(form.errors[:double_award_grade]).to be_empty
          end
        end

        it 'returns validation error if grade is blank' do
          form.validate

          expect(form.errors[:double_award_grade]).to include('Enter your science double award grade')
        end

        it 'return validation error if grade is invalid' do
          invalid_grades = %w[012 XYZ T 54%]

          invalid_grades.each do |grade|
            form.grade = grade
            form.validate

            expect(form.errors[:double_award_grade]).to include('Enter a real science double award grade')
          end
        end

        it 'logs validation errors if grade is invalid' do
          allow(Rails.logger).to receive(:info)
          form.grade = 'XYZ'

          form.save

          expect(Rails.logger).to have_received(:info).with(
            'Validation error: {:field=>"double_award_grade", :error_messages=>"Enter a real science double award grade", :value=>"XYZ"}',
          )
        end
      end

      context 'triple award' do
        let(:qualification) do
          FactoryBot.build_stubbed(
            :application_qualification,
            qualification_type: 'gcse',
            level: 'gcse',
          )
        end
        let(:form) { CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification) }

        it 'returns no errors if all grades are valid' do
          form.subject = ApplicationQualification::SCIENCE_TRIPLE_AWARD

          mistyped_grades = %w[a b c]
          valid_grades = SINGLE_GCSE_GRADES + mistyped_grades

          valid_grades.each do |grade|
            form.biology_grade = grade
            form.chemistry_grade = grade
            form.physics_grade = grade
            form.validate

            expect(form.errors[:biology_grade]).to be_empty
            expect(form.errors[:chemistry_grade]).to be_empty
            expect(form.errors[:physics_grade]).to be_empty
          end
        end

        it 'returns validation error if grade is blank' do
          form.subject = ApplicationQualification::SCIENCE_TRIPLE_AWARD
          form.validate

          expect(form.errors[:biology_grade]).to include('Enter your Biology grade')
          expect(form.errors[:chemistry_grade]).to include('Enter your Chemistry grade')
          expect(form.errors[:physics_grade]).to include('Enter your Physics grade')
        end

        it 'return validation error if one or more grades are invalid' do
          form.subject = ApplicationQualification::SCIENCE_TRIPLE_AWARD

          invalid_grades = %w[XYZ]

          invalid_grades.each do |invalid_grade|
            form.biology_grade = invalid_grade
            form.chemistry_grade = 'A'
            form.physics_grade = 'A'

            form.validate

            expect(form.errors[:biology_grade]).to include('Enter a real Biology grade')
          end
        end
      end
    end

    context 'when qualification type is GCE O LEVEL' do
      let(:qualification) { FactoryBot.build_stubbed(:application_qualification, qualification_type: 'gce_o_level', level: 'gcse', subject: 'science') }
      let(:form) { CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification) }

      it 'returns no errors if grade is valid' do
        valid_grades = ['ABC', 'AB', 'AA', 'abc', 'A B C', 'A-B-C']

        valid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to be_empty
        end
      end

      it 'return validation error if grade is invalid' do
        invalid_grades = %w[123 A* XYZ]

        invalid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to include('Enter a real science grade')
        end
      end
    end

    context 'when qualification type is Scottish National 5' do
      let(:form) { CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification) }
      let(:qualification) do
        FactoryBot.build_stubbed(:application_qualification,
                                 qualification_type: 'scottish_national_5',
                                 level: 'gcse',
                                 subject: 'science')
      end

      it 'returns no errors if grade is valid' do
        valid_grades = ['AAA', 'AAB', '765', 'CBD', 'aaa', 'C B D', 'C-B-D']

        valid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to be_empty
        end
      end

      it 'return validation error if grade is invalid' do
        invalid_grades = %w[89 AE A*]

        invalid_grades.each do |grade|
          form.grade = grade
          form.validate

          expect(form.errors[:grade]).to include('Enter a real science grade')
        end
      end
    end
  end

  context 'when saving qualification details' do
    qualification = ApplicationQualification.new
    form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

    describe '#save' do
      it 'return false if not valid' do
        expect(form.save).to eq(false)
      end

      it 'updates qualification details if valid' do
        application_form = create(:application_form)
        qualification = ApplicationQualification.create(level: 'gcse', application_form: application_form)
        details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

        details_form.grade = 'AB'

        details_form.save
        qualification.reload

        expect(qualification.grade).to eq('AB')
      end

      it 'sets grade to other_grade if candidate selected "other"' do
        application_form = create(:application_form)
        qualification = ApplicationQualification.create(level: 'gcse', application_form: application_form)
        details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

        details_form.grade = 'other'
        details_form.other_grade = 'D'

        details_form.save
        qualification.reload

        expect(qualification.grade).to eq('D')
      end

      context 'updating a GCSE  qualification from single to triple award' do
        it "clears 'grade' and populates 'grades'" do
          application_form = create(:application_form)
          qualification = ApplicationQualification.create(
            level: 'gcse',
            grade: 'A',
            subject: ApplicationQualification::SCIENCE_SINGLE_AWARD,
            application_form: application_form,
          )
          details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

          details_form.subject = ApplicationQualification::SCIENCE_TRIPLE_AWARD
          details_form.biology_grade = 'B'
          details_form.chemistry_grade = 'B'
          details_form.physics_grade = 'B'

          details_form.save
          qualification.reload

          expect(qualification.grade).to eq(nil)
          expect(qualification.grades).to eq({ 'biology' => 'B', 'physics' => 'B', 'chemistry' => 'B' })
        end
      end

      context 'updating a GCSE qualification from triple to single award' do
        it "clears 'grades' and populates 'grade'" do
          application_form = create(:application_form)
          qualification = ApplicationQualification.create(
            level: 'gcse',
            grade: nil,
            grades: { 'biology' => 'B', 'physics' => 'B', 'chemistry' => 'B' },
            subject: ApplicationQualification::SCIENCE_TRIPLE_AWARD,
            application_form: application_form,
          )
          details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

          details_form.subject = ApplicationQualification::SCIENCE_SINGLE_AWARD
          details_form.grade = 'AA'

          details_form.save
          qualification.reload

          expect(qualification.grade).to eq('AA')
          expect(qualification.grades).to eq(nil)
        end
      end
    end

    describe '.build_from_qualification' do
      context 'with the international_gcses feature flag off' do
        let(:data) do
          {
            grade: 'other',
          }
        end

        it 'creates an object based on the provided ApplicationForm' do
          qualification = ApplicationQualification.new(data)
          gcse_details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

          expect(gcse_details_form).to have_attributes(data)
        end
      end

      context 'with the international_gcses feature flag on, the qualification_type is non_uk and grade is not_applicable' do
        it 'sets grade to not_applicable and other grade to nil' do
          FeatureFlag.activate('international_gcses')
          qualification = build_stubbed(:gcse_qualification, qualification_type: 'non_uk', grade: 'n/a')
          gcse_details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

          expect(gcse_details_form.grade).to eq 'not_applicable'
          expect(gcse_details_form.other_grade).to eq nil
        end
      end

      context 'with the international_gcses feature flag on and grade is unknown' do
        it 'sets grade to not_applicable and other grade to nil' do
          FeatureFlag.activate('international_gcses')
          qualification = build_stubbed(:gcse_qualification, qualification_type: 'non_uk', grade: 'unknown')
          gcse_details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

          expect(gcse_details_form.grade).to eq 'unknown'
          expect(gcse_details_form.other_grade).to eq nil
        end
      end

      context 'with the international_gcses feature flag on and grade is another value' do
        it 'sets grade to other and other grade to grades value' do
          FeatureFlag.activate('international_gcses')
          qualification = build_stubbed(:gcse_qualification, qualification_type: 'non_uk', grade: 'D')
          gcse_details_form = CandidateInterface::ScienceGcseGradeForm.build_from_qualification(qualification)

          expect(gcse_details_form.grade).to eq 'other'
          expect(gcse_details_form.other_grade).to eq 'D'
        end
      end
    end
  end
end
