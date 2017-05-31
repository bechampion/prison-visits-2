require 'rails_helper'

RSpec.describe Nomis::Booker do
  let(:prisoner) { build(:prisoner, nomis_offender_id: 12_345) }
  let(:lead_visitor) { build(:visitor, nomis_id: 1234, sort_index: 0) }
  let(:additional_visitor) { build(:visitor, nomis_id: 2345, sort_index: 1) }
  let(:banned_visitor) { build(:visitor, nomis_id: 2345, banned: true, sort_index: 2) }

  let(:visit) do
    create(:booked_visit,
      prisoner: prisoner,
      visitors: [lead_visitor, additional_visitor, banned_visitor])
  end

  subject { described_class.new(visit) }

  shared_examples_for 'a succesful staff response' do
    let(:booking_response) { subject.book }

    it { expect(booking_response).to be_success }

    it { expect(booking_response.booking_api_error).to eq(false) }

    it 'has no errors' do
      expect(booking_response.errors).to be_empty
    end
  end

  shared_examples_for 'an unsuccesful staff response' do
    let(:booking_response) { subject.book }

    it { expect(booking_response).not_to be_success }

    it 'has no errors' do
      expect(booking_response.errors).not_to be_empty
    end
  end

  describe '#book' do
    let(:booking_response) { subject.book }

    describe 'api call to Nomis' do
      it 'with the correct parameters' do
        expect(Nomis::Api.instance).
          to receive(:book_visit).
          with(offender_id: prisoner.nomis_offender_id,
               params: {
                 lead_contact: lead_visitor.nomis_id,
                 other_visitors: [additional_visitor.nomis_id],
                 slot: visit.slot_granted.to_s,
                 override_restrictions: false,
                 client_unique_ref: visit.id
               }).and_return(Nomis::Booking.new)

        subject.book
      end
    end

    describe 'succesful booking' do
      let(:booking) { Nomis::Booking.new(visit_id: 99_999) }

      before do
        allow(Nomis::Api.instance).to receive(:book_visit).and_return(booking)
      end

      it_behaves_like 'a succesful staff response'

      it 'persists the nomis visit id on the visit' do
        expect { subject.book }.to change { visit.reload.nomis_id }.to(99_999)
      end
    end

    describe 'validation errors' do
      let(:error_message) { 'overlapping visit' }
      let(:booking) { Nomis::Booking.new(error_message: error_message) }

      before do
        allow(Nomis::Api.instance).to receive(:book_visit).and_return(booking)
      end

      it_behaves_like 'an unsuccesful staff response'

      it 'copies the error message to the errors' do
        expect(booking_response.errors).to eq([error_message])
      end

      it { expect(booking_response.booking_api_error).to eq(false) }
    end

    describe 'api errors' do
      let(:error_message) { 'timeout' }

      before do
        allow(Nomis::Api.instance).
          to receive(:book_visit).and_raise(Nomis::APIError, error_message)
      end

      it_behaves_like 'an unsuccesful staff response'

      it 'copies the error message to the errors' do
        expect(booking_response.errors).to eq([error_message])
      end

      it { expect(booking_response.booking_api_error).to eq(true) }
    end
  end
end
