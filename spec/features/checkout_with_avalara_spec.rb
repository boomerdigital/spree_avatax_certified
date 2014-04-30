require 'spec_helper'

describe "Checkout" do

  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }

  context "visitor makes checkout as guest without registration" do

    context "full checkout" do
      before do
        mug.shipping_category = shipping_method.shipping_categories.first
        mug.save!
      end

      it "works with Avalara tax calculations", :js => true do
        add_mug_to_cart
        click_button "Checkout"

        fill_in "order_email", :with => "test@example.com"
        fill_in_address

        click_button "Save and Continue"
        click_button "Save and Continue"
        click_button "Save and Continue"
        save_and_open_page
        page.should have_content("Your order has been processed successfully")
      end

    end
  end

  def fill_in_address
    address = "order_bill_address_attributes"
    fill_in "#{address}_firstname", :with => "Ryan"
    fill_in "#{address}_lastname", :with => "Bigg"
    fill_in "#{address}_address1", :with => "143 Swan Street"
    fill_in "#{address}_city", :with => "Richmond"
    select "United States of America", :from => "#{address}_country_id"
    select "Alabama", :from => "#{address}_state_id"
    fill_in "#{address}_zipcode", :with => "12345"
    fill_in "#{address}_phone", :with => "(555) 555-5555"
  end

  def add_mug_to_cart
    visit spree.root_path
    click_link mug.name
    click_button "add-to-cart-button"
  end
end
