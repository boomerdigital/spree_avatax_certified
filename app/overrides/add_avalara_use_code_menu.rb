Deface::Override.new(:virtual_path  => 'spree/admin/shared/_configuration_menu',
                     :name          => 'add_avalara_use_codes_menu_link',
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text => %q{
                        <%= configurations_sidebar_menu_item 'Avalara Settings Tax Use Codes', admin_avalara_use_code_items_path%>
                     })