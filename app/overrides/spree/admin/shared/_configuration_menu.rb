Deface::Override.new(
  virtual_path:  'spree/admin/shared/_configuration_menu',
  name:          'add_avalara_admin_menu_links',
  insert_bottom: "[data-hook='admin_configurations_sidebar_menu']"
) do
  <<-HTML
    <%= configurations_sidebar_menu_item Spree.t('avalara.settings'), admin_avatax_settings_path %>
    <%= configurations_sidebar_menu_item Spree.t('avalara_entity_use_code_settings'), admin_avalara_entity_use_codes_path %>
  HTML
end
