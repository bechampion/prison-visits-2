class BookingResponder
  class VisitorCancel < BookingRequestProcessor
    def process_request
      super do
        visit.cancel!
        Cancellation.create!(visit: visit,
                             reason: Cancellation::VISITOR_CANCELLED,
                             nomis_cancelled: false)

        BookingResponse.succesful
      end
    end
  end
end
