require 'spec_helper'
require 'data_tiering/helper_methods'

describe DataTiering::HelperMethods do

  let(:switch) { double("switch").as_null_object }

  subject do
    Class.new do
      include DataTiering::HelperMethods
    end.new
  end

  before do
    DataTiering::Switch.stub :new => switch
  end

  it 'delegates active_table_name_for to a DataTiering::Switch' do
    switch.should_receive(:active_table_name_for).with("table_name").and_return("active_table_name")
    subject.active_table_name_for("table_name").should == "active_table_name"
  end

  it 'delegates active_scope_for to a DataTiering::Switch' do
    switch.should_receive(:active_scope_for).with("model").and_return("active scope")
    subject.active_scope_for("model").should == "active scope"
  end

  it 'instantiates only one switch' do
    DataTiering::Switch.should_receive(:new).exactly(:once).and_return(switch)
    subject.active_table_name_for("table_name")
    subject.active_table_name_for("table_name")
  end

end
