Deface::Override.new(
  virtual_path:  'spree/admin/shared/_order_summary',
  name:          'add_avalara_admin_avalara_tax_total',
  insert_before: "[data-hook='admin_order_tab_total_title']"
) do
  <<-HTML
    <% if @order.adjustment_total != 0 %>
      <dt data-hook='admin_order_tab_avalara_tax_total_title'><%= Spree.t(:avalara_tax) %>:</dt>
      <dd id='adjustment_total'><%= @order.display_avalara_tax_total.to_html %></dd>
    <% end %>
  HTML
end