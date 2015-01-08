Deface::Override.new(
  virtual_path: 'spree/admin/users/_sidebar',
  name:         'add avalara information link',
  insert_bottom:   '[data-hook="admin_user_tab_options"]',
  text: "<li>
        <%= link_to 'avalara information', avalara_information_admin_user_path(@user) %>
      </li>"
)
