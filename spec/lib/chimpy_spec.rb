require 'spec_helper'

describe Spree::Chimpy do

  context "enabled" do
    before do
      Spree::Chimpy::Interface::Lists.stub(new: :lists)
      Spree::Chimpy::Interface::List.stub(new: :list)
      Spree::Chimpy::Interface::Orders.stub(new: :orders)
      config(key: '1234', lists: [{name: 'Members'}])
    end

    subject { described_class }

    specify      { should be_configured }
    specify "attributes of Spree::Chimpy when configured" do
      expect(subject.list).to eq :lists
      expect(subject.orders).to eq :orders
    end
  end

  context "disabled" do
    before { config(key: nil) }

    subject { described_class }

    specify      { should_not be_configured }
    specify "attributes of Spree::Chimpy when not configured" do
      expect(subject.list).to be_nil
      expect(subject.orders).to be_nil
    end
  end

  context "sync merge vars" do
    let(:interface)     { double(:interface) }

    before do
      Spree::Chimpy::Interface::List.stub(new: interface)
      config(key: '1234',
             lists: [{name: 'Members'}],
             merge_vars: [
                 {name: 'EMAIL', accessor: :email},
                 {name: 'FNAME', accessor: :first_name},
                 {name: 'LNAME', accessor: :last_name, options: {field_type: :text}},
                 {name: 'LAST_ORDERED', accessor: :last_ordered_at, title: 'Last Ordered', options: {field_type: :date}},
             ]
      )
    end

    it "adds var for each" do
      interface.should_receive(:merge_vars).and_return([])
      interface.should_receive(:add_merge_var).with('FNAME', 'First Name', {})
      interface.should_receive(:add_merge_var).with('LNAME', 'Last Name', {'field_type' => :text})
      interface.should_receive(:add_merge_var).with('LAST_ORDERED', 'Last Ordered', {'field_type' => :date})

      subject.sync_merge_vars
    end

    it "skips vars that exist" do
      interface.should_receive(:merge_vars).and_return(%w(EMAIL FNAME))
      interface.should_receive(:add_merge_var).with('LNAME', 'Last Name', {'field_type' => :text})
      interface.should_receive(:add_merge_var).with('LAST_ORDERED', 'Last Ordered', {'field_type' => :date})

      subject.sync_merge_vars
    end

    it "doesnt sync if all exist" do
      interface.should_receive(:merge_vars).and_return(%w(EMAIL FNAME LNAME LAST_ORDERED))
      interface.should_not_receive(:add_merge_var)

      subject.sync_merge_vars
    end
  end

  def config(options = {})
    config = Spree::Chimpy::Configuration.new
    config.key        = options[:key]
    config.lists      = options[:lists]
    config.merge_vars = options[:merge_vars]
    config
  end
end
