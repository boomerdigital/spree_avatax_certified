require 'spec_helper'

describe "VAT", :vcr do
  let!(:us) { create(:country, iso: 'US', name: 'United States') }
  let!(:it) { create(:country, iso: 'IT', name: 'Italy', iso_name: 'ITALY') }
  let!(:nl) { create(:country, iso: 'NL', name: 'Netherlands', iso_name: 'NETHERLANDS') }
  let!(:fr) { create(:country, iso: 'FR', name: 'France', iso_name: 'FRANCE') }
  let!(:cr) { create(:country, iso: 'CR', name: 'Costa Rica', iso_name: 'COSTA RICA') }

  let(:res) {
    res = avalara_order.avalara_capture
    puts res
    res
  }

  context 'Seller in EU country; Buyer in same EU country' do
    let(:it_address) { create(:address, address1: '34 Borgo degli Albizi', city: 'Florence', zipcode: '50122', country: it, state_name: '') }
    let!(:avalara_order) { create(:avalara_order, tax_included: true, ship_address: it_address, state: 'address') }
    before { prep_avalara_order }

    it 'TotalTax is equal to order included_tax_total' do
      expect(avalara_order.included_tax_total.to_f).to eq(res['TotalTax'].to_f)
    end

    it 'tax detail country equals to IT' do
      tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

      expect(tax_detail_country).to eq('IT')
    end
  end

  context 'Seller in EU country, Buyer is outside EU' do

    context 'Seller does not have Nexus Jurisdition registered' do
      let(:cr_address) { create(:address, address1: '350 Av Central', city: 'Tamarindo', zipcode: '50309', state_name: '', country: cr) }
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: cr_address, bill_address: cr_address) }

      let(:res) { avalara_order.avalara_capture }
      before { prep_avalara_order }

      it 'tax detail country equals to IT' do
        tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

        expect(tax_detail_country).to eq('IT')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['TotalTax'].to_f)
      end

      it 'total tax is 0 since utah is not in jurisdiction' do
        expect(res['TotalTax'].to_f).to eq(0)
      end

      context 'with BusinessIdentificationNo' do
        before do
          avalara_order.user.update_attributes(vat_id: '123456789')
        end

        it 'origin country zero rate is returned' do
          tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

          expect(tax_detail_country).to eq('IT')
          expect(res['TotalTax']).to eq('0')
        end
      end
    end

    context 'Seller has Nexus Jurisdiction Registered' do
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address') }
      before { prep_avalara_order }

      it 'tax detail country equals to US' do
        tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

        expect(tax_detail_country).to eq('US')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['TotalTax'].to_f)
      end
    end
  end

  context 'Seller in EU country, Buyer in another EU country' do

    context 'Seller has Nexus Jurisdition Registered' do
      let(:nl_address) { create(:address, address1: '89 Nieuwendijk', city: 'Amsterdam', zipcode: '1012 MC', country: nl, state_name: '') }
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: nl_address) }
      before { prep_avalara_order }

      it 'destination country tax is returned' do
        tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

        expect(tax_detail_country).to eq('NL')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['TotalTax'].to_f)
      end

      context 'with BusinessIdentificationNo' do
        before do
          avalara_order.user.update_attributes(vat_id: '123456789')
        end

        it 'origin country zero rate is returned' do
          tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

          expect(tax_detail_country).to eq('IT')
          expect(res['TotalTax']).to eq('0')
        end
      end
    end

    context 'Seller does not have Nexus Jurisdition Registered' do
      let(:fr_address) { create(:address, address1: '8 Boulevard du Palais', city: 'Paris', zipcode: '75001', country: fr, state_name: '') }
      let!(:avalara_order) { create(:avalara_order, tax_included: true, state: 'address', ship_address: fr_address) }
      before { prep_avalara_order }

      it 'origin country tax is returned' do
        tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']
        expect(tax_detail_country).to eq('IT')
      end

      it 'TotalTax is equal to order included_tax_total' do
        expect(avalara_order.included_tax_total.to_f).to eq(res['TotalTax'].to_f)
      end

      context 'with BusinessIdentificationNo' do
        before do
          avalara_order.user.update_attributes(vat_id: '123456789')
        end

        it 'origin country zero rate is returned' do
          tax_detail_country = res['TaxLines'][0]['TaxDetails'][0]['Country']

          expect(tax_detail_country).to eq('IT')
          expect(res['TotalTax']).to eq('0')
        end
      end
    end
  end


  def set_seller_location
    Spree::Config.avatax_origin = "{\"Address1\":\"34 Borgo degli Albizi\",\"Address2\":\"\",\"City\":\"Florence\",\"Region\":\"\",\"Zip5\":\"50122\",\"Zip4\":\"\",\"Country\":\"IT\"}"
    Spree::TaxRate.update_all(included_in_price: true)
    Spree::StockLocation.update_all(address1: '34 Borgo degli Albizi', city: 'Florence', country_id: it.id)
  end

  def prep_avalara_order
    set_seller_location
    avalara_order.reload
    avalara_order.next!
  end
end

