require 'rails_helper'

RSpec.describe Nomis::Feature do
  let(:prison_name) { 'Pentonville' }

  describe 'when the api is disabled' do
    before do
      switch_off_api
    end

    it { expect(described_class.contact_list_enabled?(anything)).to eq(false) }
    it { expect(described_class.prisoner_check_enabled?).to eq(false) }
    it { expect(described_class.prisoner_availability_enabled?).to eq(false) }
    it { expect(described_class.slot_availability_enabled?(anything)).to eq(false) }
  end

  describe 'when the api is enabled' do
    describe '.contact_list_enabled' do
      context 'with the prisoner check disabled' do
        before do
          switch_off :nomis_staff_prisoner_check_enabled
        end

        it { expect(described_class.contact_list_enabled?(anything)).to eq(false) }
      end

      context 'with the prisoner check enabled and the visit prison disabled' do
        before do
          switch_on :nomis_staff_prisoner_check_enabled
          switch_feature_flag_with(:staff_prisons_with_nomis_contact_list, [])
        end

        it { expect(described_class.contact_list_enabled?(prison_name)).to eq(false) }
      end

      context 'with the prisoner check enabled and the visit prison enabled' do
        before do
          switch_on :nomis_staff_prisoner_check_enabled
          switch_feature_flag_with(:staff_prisons_with_nomis_contact_list, [prison_name])
        end

        it { expect(described_class.contact_list_enabled?(prison_name)).to eq(true) }
      end
    end

    describe '.prisoner_check_enabled?' do
      context 'when the prisoner check is disabled' do
        before do
          switch_off :nomis_staff_prisoner_check_enabled
        end

        it { expect(described_class.prisoner_check_enabled?).to eq(false) }
      end

      context 'when the prisoner check enabled' do
        before do
          switch_on :nomis_staff_prisoner_check_enabled
        end

        it { expect(described_class.prisoner_check_enabled?).to eq(true) }
      end
    end

    describe '.prisoner_availability_enabled?' do
      context 'when the prisoner availability is disabled' do
        before do
          switch_off :nomis_staff_prisoner_availability_enabled
        end

        it { expect(described_class.prisoner_availability_enabled?).to eq(false) }
      end

      context 'when the prisoner availability enabled' do
        before do
          switch_on :nomis_staff_prisoner_availability_enabled
        end

        it { expect(described_class.prisoner_availability_enabled?).to eq(true) }
      end
    end
  end

  describe '.slot_availability_enabled?' do
    context 'when the slot availability flag is disabled' do
      before do
        switch_off :nomis_staff_slot_availability_enabled
      end

      it { expect(described_class.slot_availability_enabled?(anything)).to eq(false) }
    end

    context 'when the slot availability flag is enabled and the visit prison is not on the list' do
      before do
        switch_on :nomis_staff_slot_availability_enabled
        switch_feature_flag_with(:staff_prisons_with_slot_availability, [])
      end

      it { expect(described_class.slot_availability_enabled?(prison_name)).to eq(false) }
    end

    context 'when the slot availability flag is enabled and the visit prison is not on the list' do
      before do
        switch_on :nomis_staff_slot_availability_enabled
        switch_feature_flag_with(:staff_prisons_with_slot_availability, [prison_name])
      end

      it { expect(described_class.slot_availability_enabled?(prison_name)).to eq(true) }
    end
  end
end
