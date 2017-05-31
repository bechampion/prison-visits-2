module Nomis
  class Booker
    def initialize(visit)
      self.visit = visit
    end

    def book
      call_api
      parse_booking if booking
      booking_response
    end

  private

    attr_accessor :visit, :booking

    def call_api
      self.booking = Nomis::Api.
        instance.
        book_visit(offender_id: offender_id, params: booking_params)
    rescue Nomis::APIError => e
      booking_response.booking_api_error = true
      booking_response.errors << e.message
    end

    def parse_booking
      if booking.visit_id
        visit.update(nomis_id: booking.visit_id)
      else
        booking_response.errors << booking.error_message
      end
    end

    def offender_id
      visit.prisoner.nomis_offender_id
    end

    def booking_response
      @booking_response ||= BookingResponse.new
    end

    def booking_params
      {
        lead_contact: visit.principal_visitor.nomis_id,
        other_visitors: visit.allowed_additional_visitors.map(&:nomis_id),
        slot: visit.slot_granted.to_s,
        override_restrictions: false,
        client_unique_ref: visit.id
      }
    end
  end
end
