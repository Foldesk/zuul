require 'spec_helper'

describe "Zuul::ActiveRecord::Context" do
  before(:each) do
    User.acts_as_authorization_subject
    Role.acts_as_authorization_role
    Permission.acts_as_authorization_permission
    Context.acts_as_authorization_context
  end

  describe "allowed?" do
    it "should require a subject and a role object or slug" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      expect { context.allowed? }.to raise_exception
      expect { context.allowed?(user) }.to raise_exception
    end

    it "should wrap Subect#has_role?" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      role = Role.create(:name => "Admin", :slug => "admin", :level => 100)
      expect(context.allowed?(user, role)).to be_false
      expect(context.allowed?(user, role)).to eql(user.has_role?(role, context))
      user.assign_role(role, context)
      expect(context.allowed?(user, role)).to be_true
      expect(context.allowed?(user, role)).to eql(user.has_role?(role, context))
    end
  end

  describe "allowed_to?" do
    it "should not be available if permissions are disabled" do
      Weapon.acts_as_authorization_context :with_permissions => false
      expect(Weapon.new).to_not respond_to(:allowed_to?)
    end

    it "should require a subject and a permission object or slug" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      expect { context.allowed_to? }.to raise_exception
      expect { context.allowed_to?(user) }.to raise_exception
    end

    it "should wrap Subect#has_permission?" do
      context = Context.create(:name => "Test Context")
      user = User.create(:name => "Test User")
      permission = Permission.create(:name => "Edit", :slug => "edit")
      expect(context.allowed_to?(user, permission)).to be_false
      expect(context.allowed_to?(user, permission)).to eql(user.has_permission?(permission, context))
      user.assign_permission(permission, context)
      expect(context.allowed_to?(user, permission)).to be_true
      expect(context.allowed_to?(user, permission)).to eql(user.has_permission?(permission, context))
    end
  end

  describe "destroy_zuul_roles" do
    it "should destroy all role_subjects and roles that use this context" do
      context = Context.create(:name => 'Test Context')
      user = User.create(:name => 'Tester')
      role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      ctxtrole = Role.create(:name => 'Context Admin', :slug => 'ctxtadmin', :level => 100, :context => context)
      user.assign_role(:admin, context)
      user.assign_role(:ctxtadmin, context)
      expect(Role.count).to eql(2)
      expect(RoleUser.where(:context_type => context.class.name, :context_id => context.id).count).to eql(2)
      context.destroy
      expect(Role.count).to eql(1)
      expect(RoleUser.where(:context_type => context.class.name, :context_id => context.id).count).to eql(0)
    end
  end

  describe "destroy_zuul_permissions" do
    it "should not be available if permissions are disabled" do
      Weapon.acts_as_authorization_context :with_permissions => false
      expect(Weapon.new).to_not respond_to(:destroy_zuul_permissions)
    end
    
    it "should destroy all permission_subjects, permission_roles and permissions that use this context" do
      context = Context.create(:name => 'Test Context')
      user = User.create(:name => 'Tester')
      role = Role.create(:name => 'Admin', :slug => 'admin', :level => 100)
      perm = Permission.create(:name => 'Edit', :slug => 'edit')
      ctxtperm = Permission.create(:name => 'Context Edit', :slug => 'ctxtedit', :context => context)
      user.assign_permission(:edit, context)
      user.assign_permission(:ctxtedit, context)
      role.assign_permission(:edit, context)
      
      expect(Permission.count).to eql(2)
      expect(Permission.where(:context_type => context.class.name, :context_id => context.id).count).to eql(1)
      expect(PermissionRole.where(:context_type => context.class.name, :context_id => context.id).count).to eql(1)
      expect(PermissionUser.where(:context_type => context.class.name, :context_id => context.id).count).to eql(2)
      context.destroy
      expect(Permission.count).to eql(1)
      expect(Permission.where(:context_type => context.class.name, :context_id => context.id).count).to eql(0)
      expect(PermissionRole.where(:context_type => context.class.name, :context_id => context.id).count).to eql(0)
      expect(PermissionUser.where(:context_type => context.class.name, :context_id => context.id).count).to eql(0)
    end
  end
end
