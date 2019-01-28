class CreateSpreeAvalaraEntityUseCodes < SpreeExtension::Migration[4.2]
  def change
    create_table :spree_avalara_entity_use_codes do |t|
      t.string :use_code
      t.string :use_code_description
      t.timestamps
    end
  end
end
