require 'spec_helper'

RSpec.describe SpreeAvataxCertified::Response::AddressValidation do
  let(:response) { described_class.new(response_hash) }

  before do
    allow(response.faraday).to receive(:body).and_return(response_hash)
  end

  context 'Successful Response' do
    let(:response_hash) { build(:address_validation_success) }

    it '#validated_address' do
      validated_address = response.validated_address

      expect(validated_address['addressType']).to eq('HighRiseOrBusinessComplex')
      expect(validated_address['line1']).to eq('10 MOUNT PLEASANT AVE')
    end

    it '#messages' do
      expect(response.messages).to be_nil
    end

    it '#success?' do
      expect(response).to be_success
    end

    it '#error?' do
      expect(response).not_to be_error
    end

    it '#failed?' do
      expect(response).not_to be_failed
    end

    it '#messages_present?' do
      expect(response).not_to be_messages_present
    end

    it '#summary_messages' do
      expect(response.summary_messages).to eq([])
    end

    it '#detailed_messages' do
      expect(response.detailed_messages).to eq([])
    end
  end

  context 'Error Response' do
    context 'Missing Attributes' do
      let(:response_hash) { build(:address_validation_error) }

      it '#validated_address' do
        expect(response.validated_address).to eq({})
      end

      it '#success?' do
        expect(response).not_to be_success
      end

      it '#error?' do
        expect(response).to be_error
      end

      it '#failed?' do
        expect(response).to be_failed
      end

      it '#messages_present?' do
        expect(response).not_to be_messages_present
      end

      it '#summary_messages' do
        summaries = response.summary_messages

        expect(summaries).to be_kind_of Array
        expect(summaries.length).to eq(1)
        expect(summaries.first).to eq('The address value was incomplete.')
      end

      it '#detailed_messages' do
        details = response.detailed_messages

        expect(details).to be_kind_of Array
        expect(details.length).to eq(1)
        expect(details.first).to eq('The address value  was incomplete.  You must provide either a valid postal code, line1 + city + region, or latitude + longitude.  For international transactions outside of US/CA, only a country code is required.')
      end
    end

    context 'Unknown Address' do
      let(:response_hash) { build(:address_validation_unknown) }

      it '#validated_address' do
        expect(response.validated_address).to be_empty
      end

      it '#success?' do
        expect(response).not_to be_success
      end

      it '#error?' do
        expect(response).not_to be_error
      end

      it '#failed?' do
        expect(response).to be_failed
      end

      it '#messages_present?' do
        expect(response).to be_messages_present
      end

      it '#summary_messages' do
        summaries = response.summary_messages

        expect(summaries).to be_kind_of Array
        expect(summaries.first).to eq('The address is not deliverable.')
      end

      it '#detailed_messages' do
        details = response.detailed_messages

        expect(details).to be_kind_of Array
        expect(details.first).to eq('The physical location exists but there are no homes on this street. One reason might be railroad tracks or rivers running alongside this street, as they would prevent construction of homes in this location.')
      end
    end
  end
end
