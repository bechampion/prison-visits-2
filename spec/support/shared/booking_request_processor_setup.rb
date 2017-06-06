RSpec.shared_context 'staff response setup' do
  let(:principal_visitor) { visit.principal_visitor }
  let(:visit)             { create :visit_with_three_slots }
  let(:slot_granted)      { visit.slot_option_0 }
  let(:processing_state)  { 'requested' }
  let(:visitor_fields)    { %w[id not_on_list banned] }
  let(:params) do
    {
      slot_option_0:        visit.slot_option_0,
      slot_option_1:        visit.slot_option_1,
      slot_option_2:        visit.slot_option_2,
      slot_granted:         slot_granted,
      prison_id:            visit.prison_id,
      prisoner_id:          visit.prisoner_id,
      principal_visitor_id: visit.principal_visitor.id,
      processing_state:     processing_state,
      visitor_ids:          visit.visitor_ids,
      reference_no:         'A1234BC',
      closed:               [true, false].sample,
      rejection_attributes: {
        allowance_renews_on: {
          day: '', month: '', year: ''
        }
      },
      visitors_attributes:  {
        '0' => principal_visitor.attributes.slice(*visitor_fields).
          merge('banned_until' => principal_visitor.banned_until.to_s,
                'validate_contact_list_matching' => principal_visitor.validate_contact_list_matching?.to_s)
      }
    }
  end

  let(:user) { create(:user) }
end
