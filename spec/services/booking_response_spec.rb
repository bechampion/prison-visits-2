require 'rails_helper'

RSpec.describe BookingResponse do
  describe 'succesful' do
    subject { described_class.succesful }

    it { is_expected.to be_success }
    it { expect(subject.error).to be_nil }
  end

  describe 'already processed' do
    subject { described_class.process_required }

    it { expect(subject.error).to eq(described_class::PROCESS_REQUIRED_ERROR) }
  end

  describe 'nomis_api_error' do
    subject { described_class.nomis_api_error }

    it { expect(subject.error).to eq(described_class::NOMIS_API_ERROR) }
  end

  describe 'already_processed' do
    subject { described_class.already_processed }

    it { expect(subject.error).to eq(described_class::ALREADY_PROCESSED_ERROR) }
  end

  describe 'nomis_validation_error' do
    subject { described_class.nomis_validation_error }

    it { expect(subject.error).to eq(described_class::NOMIS_VALIDATION_ERROR) }
  end
end
