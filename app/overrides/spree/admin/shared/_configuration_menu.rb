Deface::Override.new(
  virtual_path:  'spree/admin/shared/_configuration_menu',
  name:          'add_avalara_admin_menu_links',
  insert_bottom: "[data-hook='admin_configurations_sidebar_menu']"
) do
  <<-HTML
    <%= configurations_sidebar_menu_item Spree.t('avalara.settings'), admin_avatax_settings_path %>
    <%= configurations_sidebar_menu_item Spree.t('avalara.settings_tax_use_codes'), admin_avalara_use_code_items_path %>
  HTML
end
