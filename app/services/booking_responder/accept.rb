class BookingResponder
  class Accept < BookingRequestProcessor
    def process_request(message = nil)
      super do
        visit.rejection = nil
        visit.accept!

        if visit.book_to_nomis_opt_out?
          BookingResponse.succesful
        else
          book_to_nomis
        end
      end
    end

  private

    def book_to_nomis
      booking_response = booker.book

      if booking_response.success?
        visit.update(nomis_id: booker.nomis_visit_id)
      end

      booking_response
    end

    def booker
      @booker ||= Nomis::Booker.new(visit)
    end
  end
end
