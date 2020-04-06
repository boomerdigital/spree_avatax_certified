# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Admin::AvalaraEntityUseCodesController do
  let(:avalara_entity_use_code) { FactoryBot.create(:avalara_entity_use_code) }

  stub_authorization!

  before do
    DatabaseCleaner.clean
  end

  describe '#index' do
    subject { get :index }

    it { is_expected.to be_successful }
  end

  describe '#new' do
    subject { get :new }

    it { is_expected.to be_successful }
  end

  describe '#edit' do
    subject { get :edit, params: { id: avalara_entity_use_code.id } }

    it { is_expected.to be_successful }
  end

  describe '#update' do
    subject { put :update, params: params }

    let(:params) do
      {
        id: avalara_entity_use_code.to_param,
        avalara_entity_use_code: {
          use_code: '55',
        }
      }
    end

    it { is_expected.to redirect_to(spree.admin_avalara_entity_use_codes_path) }

    it 'updates use_code' do
      expect{ subject }.to change { avalara_entity_use_code.reload.use_code }.from('A').to('55')
    end
  end
end
