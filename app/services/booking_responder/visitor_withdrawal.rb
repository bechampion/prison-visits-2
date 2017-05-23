class BookingResponder
  class VisitorWithdrawal < BookingRequestProcessor
    def process_request
      super do
        visit.withdraw!

        BookingResponse.succesful
      end
    end
  end
end
