# frozen_string_literal: true

require 'spec_helper'

describe "VAT", :vcr do
  let!(:us) { create(:country, iso: 'US') }
  let!(:it) { create(:country, iso: 'IT', iso_name: 'ITALY', name: 'Italy', iso3: 'ITA') }
  let!(:nl) { create(:country, iso: 'NL', iso_name: 'NETHERLANDS', name: 'Netherlands', iso3: 'NLD') }
  let!(:fr) { create(:country, iso: 'FR', iso_name: 'FRANCE', name: 'France', iso3: 'FRA') }
  let!(:cr) { create(:country, iso: 'CR', iso_name: 'COSTA RICA', name: 'Costa Rica', iso3: 'CRI') }
  let!(:seller_location) { create(:stock_location, address1: '34 Borgo degli Albizi', city: 'Florence', zipcode: '50122', country: it) }

  let(:it_address) { create(:address, address1: '34 Borgo degli Albizi', city: 'Florence', zipcode: '50122', country: it, state: nil, state_name: '') }
  let(:res) { avalara_order.avalara_capture }

  context 'Seller in EU country; Buyer in same EU country' do
    let!(:avalara_order) { create(:avalara_order, tax_included: true, ship_address: it_address, state: 'address') }

    before { prep_avalara_order }

    it 'TotalTax is equal to order included_tax_total' do
      expect(avalara_order.included_tax_total.to_f).to eq(res['totalTax'].to_f)
    end

    it 'tax detail country equals to IT' do
      tax_detail_country = res['lines'][0]['details'][0]['country']

      expect(tax_detail_country).to eq('IT')
    end
  end

  context 'Seller in EU country, Buyer is outside EU' do
    context 'Seller does not have Nexus Jurisdition registered' do
      let(:cr_address) { create(:address, address1: '350 Av Central', city: 'Tamarindo', zipcode: '50309', state: nil, state_name: '', country: cr) }
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: cr_address) }

      let(:res) { avalara_order.avalara_capture }

      before { prep_avalara_order }

      it 'tax detail country equals to IT' do
        tax_detail_country = res['lines'][0]['details'][0]['country']

        expect(tax_detail_country).to eq('IT')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['totalTax'].to_f)
      end

      it 'total tax is 0 since utah is not in jurisdiction' do
        expect(res['totalTax'].to_f).to eq(0)
      end

      context 'with BusinessIdentificationNo' do
        before do
          avalara_order.user.update(vat_id: '123456789')
        end

        it 'origin country zero rate is returned' do
          tax_detail_country = res['summary'][0]['country']

          expect(tax_detail_country).to eq('IT')
          expect(res['totalTax']).to eq(0)
        end
      end
    end

    context 'Seller has Nexus Jurisdiction Registered' do
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address') }

      before { prep_avalara_order }

      it 'tax detail region equals to IT' do
        tax_detail_region = res['lines'][0]['details'][0]['region']

        expect(tax_detail_region).to eq('IT')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['totalTax'].to_f)
      end
    end
  end

  context 'Seller in EU country, Buyer in another EU country' do
    context 'Seller has Nexus Jurisdition Registered' do
      let(:nl_address) { create(:address, address1: '89 Nieuwendijk', city: 'Amsterdam', zipcode: '1012 MC', country: nl, state_name: '', state: nil) }
      let(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: nl_address) }

      before { prep_avalara_order }

      it 'destination country tax is returned' do
        tax_detail_country = res['lines'][0]['details'][0]['country']

        expect(tax_detail_country).to eq('NL')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['totalTax'].to_f)
      end

      context 'with BusinessIdentificationNo' do
        let(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: nl_address, user: create(:user, vat_id: '123456789')) }

        it 'origin country zero rate is returned' do
          tax_detail_country = res['summary'][0]['country']

          expect(tax_detail_country).to eq('IT')
          expect(res['totalTax']).to eq(0)
        end
      end
    end

    context 'Seller does not have Nexus Jurisdition Registered' do
      let(:fr_address) { create(:address, address1: '8 Boulevard du Palais', city: 'Paris', zipcode: '75001', country: fr, state_name: '', state: nil) }
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: fr_address) }

      before { prep_avalara_order }

      it 'origin country tax is returned' do
        tax_detail_country = res['summary'][0]['country']
        expect(tax_detail_country).to eq('IT')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['totalTax'].to_f)
      end

      context 'with BusinessIdentificationNo' do
        before do
          avalara_order.user.update(vat_id: '123456789')
        end

        it 'origin country zero rate is returned' do
          tax_detail_country = res['summary'][0]['country']

          expect(tax_detail_country).to eq('IT')
          expect(res['totalTax']).to eq(0)
        end
      end
    end
  end

  def set_seller_location
    Spree::Config.avatax_origin = "{\"line1\":\"34 Borgo degli Albizi\",\"city\":\"Florence\",\"region\":\"\",\"postalCode\":\"50122\",\"country\":\"IT\"}"
    Spree::StockLocation.update_all(address1: '150 Piccadilly', city: 'Florence', country_id: it.id, state_id: nil)
  end

  def prep_avalara_order
    avalara_order.reload
    set_seller_location
    avalara_order.next!
  end
end
