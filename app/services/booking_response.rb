class BookingResponse
  def self.succesful
    new(errors: [])
  end

  attr_reader :errors
  attr_writer :booking_api_error

  def initialize(errors: [])
    self.errors = errors
  end

  def success?
    errors.empty?
  end

  def booking_api_error
    !!@booking_api_error
  end

private

  attr_writer :errors
end
