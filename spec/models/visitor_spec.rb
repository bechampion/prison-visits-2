require 'rails_helper'

RSpec.describe Visitor do
  subject(:instance) { FactoryGirl.build(:visitor) }

  it { is_expected.to belong_to(:visit) }
  it { is_expected.to validate_presence_of(:visit) }
  it { is_expected.to validate_presence_of(:first_name) }
  it { is_expected.to validate_presence_of(:last_name) }
  it { is_expected.to validate_presence_of(:date_of_birth) }

  describe 'contact list processing' do
    context 'the validation is disabled by default' do
      it { is_expected.to be_valid }
    end

    context 'with the validation enabled' do
      before do
        subject.validate_contact_list_matching = 'true'
      end

      describe 'with a nomis_id and not on the list' do
        before do
          subject.nomis_id = 12_345
          subject.not_on_list = true
        end

        it 'is invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).
            to eq([
              I18n.t('unprocessed_contact_list',
                scope: %i[activerecord errors models visitor])
          ])
        end
      end

      describe 'with no nomis_id and on the list' do
        before do
          subject.nomis_id = nil
          subject.not_on_list = nil
        end

        it 'is invalid' do
          expect(subject).not_to be_valid
          expect(subject.errors.full_messages).
            to eq([
              I18n.t('unprocessed_contact_list',
                scope: %i[activerecord errors models visitor])
          ])
        end
      end

      describe 'with no nomis_id and not on the list' do
        before do
          subject.nomis_id = nil
          subject.not_on_list = true
        end

        it { is_expected.to be_valid }
      end

      describe 'with a nomis_id and on the list' do
        before do
          subject.nomis_id = 12_345
          subject.not_on_list = nil
        end

        it { is_expected.to be_valid }
      end
    end
  end

  describe '#allowed?' do
    subject { instance.allowed? }

    before do
      instance.not_on_list = not_on_list
      instance.banned = banned
    end

    context 'when not banned or is the contact list' do
      let(:not_on_list) { false }
      let(:banned) { false }

      it { is_expected.to eq(true) }
    end

    context 'when banned' do
      let(:not_on_list) { false }
      let(:banned) { true }

      it { is_expected.to eq(false) }
    end

    context 'when not in the contact list' do
      let(:not_on_list) { true }
      let(:banned) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '#status' do
    subject { instance.status }

    context 'when is allowed' do
      it { is_expected.to eq('allowed') }
    end

    context 'when is banned' do
      before do
        instance.banned = true
      end

      it { is_expected.to eq('banned') }
    end

    context 'when is not on the list' do
      before do
        instance.not_on_list = true
      end

      it { is_expected.to eq('not on list') }
    end
  end
end
