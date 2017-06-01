require 'rails_helper'

RSpec.describe Nomis::Booker do
  let(:prisoner) { build_stubbed(:prisoner, nomis_offender_id: 12_345) }
  let(:lead_visitor) { build_stubbed(:visitor, nomis_id: 1234, sort_index: 0) }
  let(:additional_visitor) { build_stubbed(:visitor, nomis_id: 2345, sort_index: 1) }
  let(:banned_visitor) { build_stubbed(:visitor, nomis_id: 2345, banned: true, sort_index: 2) }

  let(:visit) do
    build_stubbed(:booked_visit,
      prisoner: prisoner,
      visitors: [lead_visitor, additional_visitor, banned_visitor])
  end

  subject { described_class.new(visit) }

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

      it { expect(subject.book).to be_success }
    end

    describe 'validation errors' do
      let(:error_message) { 'overlapping visit' }
      let(:booking) { Nomis::Booking.new(error_message: error_message) }

      before do
        allow(Nomis::Api.instance).to receive(:book_visit).and_return(booking)
      end

      it { expect(subject.book).not_to be_success }
      it { expect(subject.book).to have_attributes(error: BookingResponse::NOMIS_VALIDATION_ERROR) }
    end

    describe 'api errors' do
      let(:error_message) { 'timeout' }

      before do
        allow(Nomis::Api.instance).
          to receive(:book_visit).and_raise(Nomis::APIError, error_message)
      end

      it { expect(subject.book).not_to be_success }
      it { expect(subject.book).to have_attributes(error: BookingResponse::NOMIS_API_ERROR) }
    end

    describe 'duplicate post' do
      let(:error_message) { 'Duplicate post' }

      let(:booking) { Nomis::Booking.new(error_message: error_message) }

      before do
        allow(Nomis::Api.instance).to receive(:book_visit).and_return(booking)
      end

      it { expect(subject.book).not_to be_success }
      it { expect(subject.book).to have_attributes(error: BookingResponse::ALREADY_PROCESSED_ERROR) }
    end
  end
end
