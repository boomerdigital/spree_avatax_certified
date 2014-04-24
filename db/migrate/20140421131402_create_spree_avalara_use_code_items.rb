class CreateSpreeAvalaraUseCodeItems < ActiveRecord::Migration
  def change
    create_table :spree_avalara_use_code_items do |t|
      t.string :use_code
      t.string :use_code_description
      t.timestamps
    end
  end
end
