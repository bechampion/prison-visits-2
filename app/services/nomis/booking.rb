module Nomis
  class Booking
    include NonPersistedModel

    attribute :visit_id, Integer
  end
end
