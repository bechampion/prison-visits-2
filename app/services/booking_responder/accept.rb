class BookingResponder
  class Accept < BookingRequestProcessor
    def process_request(message = nil)
      super do
        visit.rejection = nil
        visit.accept!

        if visit.book_to_nomis_opt_out?
          BookingResponse.succesful
        else
          booker.book
        end
      end
    end

  private

    def booker
      @booker ||= Nomis::Booker.new(visit)
    end
  end
end
