Deface::Override.new(:virtual_path  => 'spree/admin/layouts/admin',
                     :name          => 'add_avalara_js_routes',
                     :insert_bottom => "[data-hook='admin_inside_head']",
                     :text => %q{
<script>
Spree.routes.use_code_search = "<%= spree.admin_avalara_use_code_items_url(:format => 'json') %>"
</script>
                     })
