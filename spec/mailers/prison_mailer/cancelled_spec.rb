require 'rails_helper'
require 'mailers/shared_mailer_examples'

RSpec.describe PrisonMailer, '.cancelled' do
  let(:prisoner) {
    create(
      :prisoner,
      first_name: 'Arthur',
      last_name: 'Raffles'
    )
  }

  let(:mail) { described_class.cancelled(visit) }

  around do |example|
    ActionMailer::Base.deliveries.clear
    travel_to(Date.new(2015, 6, 1)) do
      example.run
    end
  end

  context 'cancelled visit' do
    let(:visit) { create(:cancelled_visit, prisoner: prisoner) }
    include_examples 'template checks'

    it 'sends an email notifyting the prison of the cancellation' do
      expect(mail.subject).to eq('CANCELLED: Arthur Raffles on Monday 8 June')
      expect(mail['X-Priority'].value).to eq('1 (Highest)')
      expect(mail['X-MSMail-Priority'].value).to eq('High')
    end

    it 'sends an email containing the visit id and reference number' do
      expect(mail.body.encoded).to match(prisoner.number)
      expect(mail.body.encoded).to match(visit.id)
    end
  end

  context 'withdrawn visit' do
    let(:visit) { create(:withdrawn_visit, prisoner: prisoner) }
    include_examples 'template checks'

    it 'sends an email notifyting the prison of the withdrawal' do
      expect(mail.subject).to eq('WITHDRAWN: Arthur Raffles on Monday 8 June')
      expect(mail['X-Priority'].value).to eq('1 (Highest)')
      expect(mail['X-MSMail-Priority'].value).to eq('High')
    end
  end
end
