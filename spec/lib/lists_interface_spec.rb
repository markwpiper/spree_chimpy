require 'spec_helper'

describe Spree::Chimpy::Interface::Lists do
  let(:list_interface1) { double(:list_interface1) }
  let(:list_interface2) { double(:list_interface2) }

  let(:interface) { described_class.new([list_interface1, list_interface2]) }
  let(:api)       { double(:api) }
  let(:key)       { 'e025fd58df5b66ebd5a709d3fcf6e600-us8' }

  before do
    Spree::Chimpy::Config.key = key
    Spree::Chimpy::Config.enabled = true
  end

  context '#subscribe' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:subscribe).with('user@example.com', 'SIZE' => '10')
      expect(list_interface2).to receive(:subscribe).with('user@example.com', 'SIZE' => '10')
      interface.subscribe('user@example.com', 'SIZE' => '10')
    end
  end

  context '#unsubscribe' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:unsubscribe).with('user@example.com')
      expect(list_interface2).to receive(:unsubscribe).with('user@example.com')
      interface.unsubscribe('user@example.com')
    end
  end

  context '#update_subscriber' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:update_subscriber).with('user@example.com', 'foo' => 'bar')
      expect(list_interface2).to receive(:update_subscriber).with('user@example.com', 'foo' => 'bar')
      interface.update_subscriber('user@example.com', 'foo' => 'bar')
    end
  end

  context '#sync_merge_vars' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:sync_merge_vars).with(no_args)
      expect(list_interface2).to receive(:sync_merge_vars).with(no_args)
      interface.sync_merge_vars
    end
  end

  context '#ensure_list' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:ensure_list).with(no_args)
      expect(list_interface2).to receive(:ensure_list).with(no_args)
      interface.ensure_list
    end
  end

  context '#ensure_segment' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:ensure_segment).with(no_args)
      expect(list_interface2).to receive(:ensure_segment).with(no_args)
      interface.ensure_segment
    end
  end

  context '#create_segment' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:create_segment).with('tag', 'description', {option1: :foo})
      expect(list_interface2).to receive(:create_segment).with('tag', 'description', {option1: :foo})
      interface.create_segment('tag', 'description', {option1: :foo})
    end
  end

  context '#add_merge_var' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:add_merge_var).with(no_args)
      expect(list_interface2).to receive(:add_merge_var).with(no_args)
      interface.add_merge_var
    end
  end

  context '#segment' do
    it 'delegates to each list' do
      expect(list_interface1).to receive(:segment).with(['email1','email2','email3'])
      expect(list_interface2).to receive(:segment).with(['email1','email2','email3'])
      interface.segment(['email1','email2','email3'])
    end
  end
end
