Deface::Override.new(
  virtual_path:  'spree/admin/shared/sub_menu/_configuration',
  name:          'add_avalara_admin_menu_links',
  insert_bottom: "[data-hook='admin_configurations_sidebar_menu']"
) do
  <<-HTML
    <%= configurations_sidebar_menu_item Spree.t('avalara.settings'), spree.admin_avatax_settings_path %>
    <%= configurations_sidebar_menu_item Spree.t('avalara_entity_use_code_settings'), spree.admin_avalara_entity_use_codes_path %>
  HTML
end
