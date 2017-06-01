class BookingResponse
  ALREADY_PROCESSED_ERROR = 'already_processed'.freeze
  PROCESS_REQUIRED_ERROR = 'process_required'.freeze
  NOMIS_VALIDATION_ERROR = 'nomis_validation_error'.freeze
  NOMIS_API_ERROR = 'nomis_api_error'.freeze

  attr_reader :error

  def self.succesful
    new(nil)
  end

  def self.process_required
    new(PROCESS_REQUIRED_ERROR)
  end

  def self.nomis_validation_error
    new(NOMIS_VALIDATION_ERROR)
  end

  def self.nomis_api_error
    new(NOMIS_API_ERROR)
  end

  def self.already_processed
    new(ALREADY_PROCESSED_ERROR)
  end

  def initialize(error)
    self.error = error
  end

  def success?
    error.nil?
  end

  def already_processed?
    error == ALREADY_PROCESSED_ERROR
  end

private

  attr_writer :error
end
