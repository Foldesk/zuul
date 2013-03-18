require 'spec_helper'

describe "Zuul::ActiveRecord::Permission" do
  
  describe "accessible attributes" do
    before(:each) do
      Permission.acts_as_authorization_permission
    end
    
    it "should allow mass assignment of :name" do
      permission = Permission.new(:name => 'Edit')
      permission.name.should == 'Edit'
    end
    
    it "should allow mass assignment of :slug" do
      permission = Permission.new(:slug => 'edit')
      permission.slug.should == 'edit'
    end
    
    it "should allow mass assignment of :context" do
      context = Context.create(:name => "Test Context")
      permission = Permission.new(:context => context)
      permission.context_type.should == 'Context'
      permission.context_id.should == context.id
    end
    
    it "should allow mass assignment of :context_type" do
      permission = Permission.new(:context_type => 'Context')
      permission.context_type.should == 'Context'
    end
    
    it "should allow mass assignment of :context_id" do
      permission = Permission.new(:context_id => 1)
      permission.context_id.should == 1
    end
  end
  
  context "validations for core permission fields" do
    before(:each) do
      Permission.acts_as_authorization_permission
    end
    
    it "should validate presence of name" do
      permission = Permission.new(:slug => 'edit')
      permission.valid?.should be_false
      permission.errors.keys.should include(:name)
    end

    it "should validate presence of slug" do
      permission = Permission.new(:name => 'Edit')
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
    end

    it "should validate format of slug" do
      permission = Permission.new(:name => 'Edit', :slug => 'edit')
      permission.valid?.should be_true
      permission.slug = 'adm in'
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      permission.slug = 'ad*&^;'
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      permission.slug = '{:edit}'
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
    end
    
    it "should validate uniqueness of slug scoped to context_type, context_id" do
      Permission.create(:name => 'Edit', :slug => 'edit')
      permission = Permission.new(:name => 'Edit', :slug => 'edit')
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      
      Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context').valid?.should be_true
      permission = Permission.new(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
      
      Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => 1).valid?.should be_true
      permission = Permission.new(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => 1)
      permission.valid?.should be_false
      permission.errors.keys.should include(:slug)
    end
  end
  
  it "should provide the model with has_many associations for permission_subjects and subjects" do
    Permission.acts_as_authorization_permission
    Permission.reflections.keys.should include(:permission_users)
    Permission.reflections.keys.should include(:users)
    permission = Permission.create(:name => 'Edit', :slug => 'edit')
    permission.should respond_to(:permission_users)
    permission.should respond_to(:users)
  end
  
  it "should use the reflection classes to create the has_many associations" do
    Skill.acts_as_authorization_permission :subject_class => :soldier, :role_class => :rank
    Skill.reflections.keys.should include(:skill_soldiers)
    Skill.reflections.keys.should include(:soldiers)
    skill = Skill.create(:name => 'Marksman', :slug => 'marksman')
    skill.should respond_to(:skill_soldiers)
    skill.should respond_to(:soldiers)
  end
  
  it "should provide the model with has_many associations for permission_roles and roles" do
    Permission.acts_as_authorization_permission
    Permission.reflections.keys.should include(:permission_roles)
    Permission.reflections.keys.should include(:roles)
    permission = Permission.create(:name => 'Edit', :slug => 'edit')
    permission.should respond_to(:permission_roles)
    permission.should respond_to(:roles)
  end
  
  it "should use the reflection classes to create the has_many associations" do
    Skill.acts_as_authorization_permission :subject_class => :soldier, :role_class => :rank
    Skill.reflections.keys.should include(:rank_skills)
    Skill.reflections.keys.should include(:ranks)
    skill = Skill.create(:name => 'Marksman', :slug => 'marksman')
    skill.should respond_to(:rank_skills)
    skill.should respond_to(:ranks)
  end

  describe "#context" do
    before(:each) do
      Permission.acts_as_authorization_permission
    end
    
    it "should return a Zuul::Context object" do
      permission = Permission.create(:name => 'Edit', :slug => 'edit')
      permission.context.should be_a(Zuul::Context)
    end

    it "should return a Zuul::Context object that represents the context of the permission" do
      context = Context.create(:name => "Test Context")
      nil_permission = Permission.create(:name => 'Edit', :slug => 'edit')
      class_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context')
      inst_permission = Permission.create(:name => 'Edit', :slug => 'edit', :context_type => 'Context', :context_id => context.id)
      nil_permission.context.to_context.should be_nil
      class_permission.context.to_context.should == Context
      inst_permission.context.to_context.should be_a(Context)
      inst_permission.context.to_context.id.should == context.id
    end
  end

  describe "#context=" do
    before(:each) do
      Permission.acts_as_authorization_permission
      @permission = Permission.create(:name => 'Edit', :slug => 'edit')
    end

    it "should allow passing a nil context" do
      expect { @permission.context = nil }.to_not raise_exception
    end

    it "should allow passing a class context" do
      expect { @permission.context = Context }.to_not raise_exception
    end
    
    it "should allow passing an instance context" do
      context = Context.create(:name => "Test Context")
      expect { @permission.context = context }.to_not raise_exception
    end
    
    it "should allow passing an existing Zuul::Context" do
      expect { @permission.context = Zuul::Context.new }.to_not raise_exception
    end

    it "should accept a context and set the context_type and context_id based on the passed context" do
      context = Context.create(:name => "Test Context")
      @permission.context_type.should be_nil
      @permission.context_id.should be_nil
      @permission.context = Context
      @permission.context_type.should == "Context"
      @permission.context_id.should be_nil
      @permission.context = context
      @permission.context_type.should == "Context"
      @permission.context_id.should == context.id
    end
  end
end
