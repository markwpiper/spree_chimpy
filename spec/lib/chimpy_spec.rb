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
                 {name: 'FNAME', accessor: :first_name}
             ]
      )
    end

    it "delegates to lists.sync_merge_vars" do
      interface.should_receive(:sync_merge_vars).with(no_args)
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
