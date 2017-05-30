require 'rails_helper'

RSpec.describe VisitDecorator do
  let(:visit) { create(:visit) }

  subject(:instance) { described_class.decorate(visit) }

  describe '#slots'do
    it 'are decorated object' do
      expect(subject.slots).to all(be_decorated)
    end
  end

  describe '#nomis_offender_id' do
    context 'when the lookup is disabled' do
      before do
        switch_off(:nomis_staff_prisoner_check_enabled)
      end

      it 'returns nil' do
        expect(subject.nomis_offender_id).to be_nil
      end
    end

    context 'when the lookup is enabled' do
      let(:checker) { double(StaffNomisChecker) }
      let(:offender) { double(Nomis::Offender, id: 1234) }

      before do
        switch_on(:nomis_staff_prisoner_check_enabled)
        mock_service_with(StaffNomisChecker, checker)
        expect(checker).to receive(:offender).and_return(offender)
      end

      it 'returns the offender id' do
        expect(subject.nomis_offender_id).to eq(offender.id)
      end
    end
  end

  describe '#processed_at' do
    subject(:processed_at) { instance.processed_at }

    context 'when requested' do
      let(:visit) { create(:visit, :requested) }

      it 'returns the visit creation time' do
        expect(processed_at).to eq(visit.created_at)
      end
    end

    context 'when not requested' do
      let!(:last_state_change) do
        VisitStateChange.create!(visit: visit,
                                 visit_state: 'cancelled',
                                 created_at: 1.day.from_now)
      end

      it 'returns the last visit state change creation time' do
        expect(processed_at).to eq(last_state_change.reload.created_at)
      end
    end
  end

  describe '#book_to_nomis_opt_in?' do
    let(:nomis_checker) { instance_double(StaffNomisChecker) }

    describe 'when the book to nomis feature is disabled' do
      before do
        switch_off :nomis_staff_book_to_nomis_enabled
      end

      it { expect(subject.book_to_nomis_opt_in?).to eq(false) }
    end

    describe 'when the book to nomis feature is enabled' do
      before do
        switch_on :nomis_staff_book_to_nomis_enabled
        switch_feature_flag_with(:staff_prisons_with_book_to_nomis, [visit.prison_name])
      end

      describe 'when the contact list feature is disabled' do
        before do
          switch_feature_flag_with(:staff_prisons_with_nomis_contact_list, [])
        end

        it { expect(subject.book_to_nomis_opt_in?).to eq(false) }
      end

      describe 'when the contact list feature is enabled and not working' do
        before do
          mock_service_with(StaffNomisChecker, nomis_checker)
          switch_feature_flag_with(:staff_prisons_with_nomis_contact_list, [visit.prison_name])
          expect(nomis_checker).to receive(:contact_list_unknown?).and_return(true)
        end

        it { expect(subject.book_to_nomis_opt_in?).to eq(false) }
      end

      describe 'when the contact list feature is enabled and working' do
        before do
          mock_service_with(StaffNomisChecker, nomis_checker)
          switch_feature_flag_with(:staff_prisons_with_nomis_contact_list, [visit.prison_name])
          expect(nomis_checker).to receive(:contact_list_unknown?).and_return(false)
        end

        describe "when the visit hasn't set the book to nomis opt out flag" do
          before do
            visit.book_to_nomis_opt_out = nil
          end

          it { expect(subject.book_to_nomis_opt_in?).to eq(true) }
        end

        describe "when the visit has book to nomis opt out flag set to false" do
          before do
            visit.book_to_nomis_opt_out = false
          end

          it { expect(subject.book_to_nomis_opt_in?).to eq(true) }
        end

        describe "when the visit has book to nomis opt out flag set to true" do
          before do
            visit.book_to_nomis_opt_out = true
          end

          it { expect(subject.book_to_nomis_opt_in?).to eq(false) }
        end
      end
    end
  end
end
