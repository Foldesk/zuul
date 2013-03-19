class ZuulPermissionRoleCreate<%= table_name.camelize %> < ActiveRecord::Migration
  def change
    create_table(:<%= table_name %>) do |t|
<% attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %>
<% end -%>

      t.timestamps
    end

    add_index :<%= table_name %>, :<%= permission_model.to_s.underscore.singularize %>_id
    add_index :<%= table_name %>, :<%= role_model.to_s.underscore.singularize %>_id
    add_index :<%= table_name %>, :context_type
    add_index :<%= table_name %>, :context_id
    add_index :<%= table_name %>, [:<%= permission_model.to_s.underscore.singularize %>_id, :<%= role_model.to_s.underscore.singularize %>_id, :context_type, :context_id], :unique => true
  end
end
