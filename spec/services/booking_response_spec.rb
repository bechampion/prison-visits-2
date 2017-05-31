require 'rails_helper'

RSpec.describe BookingResponse do
  subject { described_class.new(errors: errors) }

  describe '#already_processed?' do
    context 'when it has no duplicate post error' do
      let(:errors) { 'random' }

      it { expect(subject).not_to be_already_processed }
    end

    context "when it has a 'Duplicate post'" do
      let(:errors) { 'Duplicate post' }

      it { expect(subject).to be_already_processed }
    end
  end
end
