FactoryGirl.define do
  factory :cancellation do
    association :visit, processing_state: 'cancelled'
    reason 'prisoner_moved'
  end
end
