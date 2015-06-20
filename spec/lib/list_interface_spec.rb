require 'spec_helper'

describe Spree::Chimpy::Interface::List do
  let(:customer_segment_name) { 'customers' }
  let(:list_name)             { 'Members' }
  let(:list_id)               { 'a3d3' }

  let(:interface) { described_class.new(list_name, customer_segment_name, true, true, nil) }
  let(:api)       { double(:api) }
  let(:lists)     { double(:lists, :[] => [{'name' => list_name, 'id' => list_id}] ) }
  let(:key)       { 'e025fd58df5b66ebd5a709d3fcf6e600-us8' }

  before do
    Spree::Chimpy::Config.key = key
    Spree::Chimpy::Config.enabled = true
    Mailchimp::API.should_receive(:new).with(key, { timeout: 60 }).and_return(api)
    lists.stub(:list).and_return(lists)
    api.stub(:lists).and_return(lists)
  end

  context '#subscribe' do
    it 'subscribes' do
      expect(lists).to receive(:subscribe).
        with('a3d3', {email: 'user@example.com'},
              {'SIZE' => '10'}, 'html', true, true, true, true)
      interface.subscribe('user@example.com', 'SIZE' => '10')
    end

    it 'ignores exception Mailchimp::ListInvalidImportError' do
      expect(lists).to receive(:subscribe).
        with('a3d3', {email: 'user@example.com'},
              {}, 'html', true, true, true, true).and_raise Mailchimp::ListInvalidImportError
      expect(lambda { interface.subscribe('user@example.com') }).not_to raise_error
    end
  end

  context '#update_subscriber' do
    it 'updates the subscriber' do
      expect(lists).to receive(:update_member).
                           with('a3d3', {email: 'user@example.com'}, {'SIZE' => '10'})
      interface.update_subscriber('user@example.com', 'SIZE' => '10')
    end

    it 'ignores exception Mailchimp::ListInvalidImportError' do
      expect(lists).to receive(:update_member).
                           with('a3d3', {email: 'user@example.com'}, {}).and_raise Mailchimp::ListInvalidImportError
      expect(lambda { interface.update_subscriber('user@example.com') }).not_to raise_error
    end

    it 'ignores exception Mailchimp::ValidationError' do
      expect(lists).to receive(:update_member).
                           with('a3d3', {email: 'user@example.com'}, {}).and_raise Mailchimp::ValidationError
      expect(lambda { interface.update_subscriber('user@example.com') }).not_to raise_error
    end

    it 'ignores exception Mailchimp::EmailNotExistsError' do
      expect(lists).to receive(:update_member).
                           with('a3d3', {email: 'user@example.com'}, {}).and_raise Mailchimp::EmailNotExistsError
      expect(lambda { interface.update_subscriber('user@example.com') }).not_to raise_error
    end

    it 'ignores exception Mailchimp::ListNotSubscribedError' do
      expect(lists).to receive(:update_member).
                           with('a3d3', {email: 'user@example.com'}, {}).and_raise Mailchimp::ListNotSubscribedError
      expect(lambda { interface.update_subscriber('user@example.com') }).not_to raise_error
    end
  end

  context '#unsubscribe' do
    it 'unsubscribes' do
      expect(lists).to receive(:unsubscribe).with('a3d3', { email: 'user@example.com' })
      interface.unsubscribe('user@example.com')
    end

    it 'ignores exception Mailchimp::EmailNotExistsError' do
      expect(lists).to receive(:unsubscribe).with('a3d3', { email: 'user@example.com' }).and_raise Mailchimp::EmailNotExistsError
      expect(lambda { interface.unsubscribe('user@example.com') }).not_to raise_error
    end

    it 'ignores exception Mailchimp::ListNotSubscribedError' do
      expect(lists).to receive(:unsubscribe).with('a3d3', { email: 'user@example.com' }).and_raise Mailchimp::ListNotSubscribedError
      expect(lambda { interface.unsubscribe('user@example.com') }).not_to raise_error
    end
  end

  context 'member info' do
    it 'find when no errors' do
      expect(lists).to receive(:member_info).with('a3d3', [{:email=> 'user@example.com'}]).and_return({'success_count' => 1, 'data' => [{'response' => 'foo'}]})
      expect(interface.info('user@example.com')).to eq({:response => 'foo'})
    end

    it 'returns empty hash on error' do
      expect(lists).to receive(:member_info).with('a3d3', [{:email=>'user@example.com'}]).and_return({'data' => [{'error' => 'foo'}]})
      expect(interface.info('user@example.com')).to eq({})
    end
  end

  it 'segments users' do
    expect(lists).to receive(:subscribe).
      with('a3d3', {email: 'user@example.com'}, {'SIZE' => '10'},
            'html', true, true, true, true)
    expect(lists).to receive(:static_segments).with('a3d3').and_return([{'id' => 123, 'name' => 'customers'}])
    expect(lists).to receive(:static_segment_members_add).with('a3d3', 123, [{:email => 'user@example.com'}])
    interface.subscribe('user@example.com', {'SIZE' => '10'}, {customer: true})
  end

  it 'segments' do
    expect(lists).to receive(:static_segments).with('a3d3').and_return([{'id' => '123', 'name' => 'customers'}])
    expect(lists).to receive(:static_segment_members_add).with('a3d3', 123, [{email: 'test@test.nl'}, {email: 'test@test.com'}])
    interface.segment(['test@test.nl', 'test@test.com'])
  end

  it 'find list id' do
    interface.list_id
  end

  it 'checks if merge var exists' do
    expect(lists).to receive(:merge_vars).with(['a3d3']).and_return( {'success_count' => 1,
                                                                     'data' => [{'id' => 'a3d3',
                                                                                'merge_vars' => [{'tag' => 'FOO'},
                                                                                                 {'tag' => 'BAR'}] }]} )
    expect(interface.merge_vars).to match_array %w(FOO BAR)
  end

  it 'adds a merge var' do
    expect(lists).to receive(:merge_var_add).with('a3d3', 'SIZE', 'Your Size', field_type: 'text')
    interface.add_merge_var('SIZE', 'Your Size', {field_type: 'text'})
  end

  context 'sync merge vars' do
    before do
      Spree::Chimpy::Config.merge_vars = [
          {name: 'EMAIL', accessor: :email},
          {name: 'FNAME', accessor: :first_name},
          {name: 'LNAME', accessor: :last_name, options: {field_type: :text}},
          {name: 'LAST_ORDERED', accessor: :last_ordered_at, title: 'Last Ordered', options: {field_type: :date}},
      ]
    end

    it 'adds var for each' do
      expect(interface).to receive(:merge_vars).and_return([])
      expect(interface).to receive(:add_merge_var).with('FNAME', 'First Name', {})
      expect(interface).to receive(:add_merge_var).with('LNAME', 'Last Name', {'field_type' => :text})
      expect(interface).to receive(:add_merge_var).with('LAST_ORDERED', 'Last Ordered', {'field_type' => :date})

      interface.sync_merge_vars
    end

    it 'skips vars that exist' do
      expect(interface).to receive(:merge_vars).and_return(%w(EMAIL FNAME))
      expect(interface).to receive(:add_merge_var).with('LNAME', 'Last Name', {'field_type' => :text})
      expect(interface).to receive(:add_merge_var).with('LAST_ORDERED', 'Last Ordered', {'field_type' => :date})

      interface.sync_merge_vars
    end

    it 'doesnt sync if all exist' do
      expect(interface).to receive(:merge_vars).and_return(%w(EMAIL FNAME LNAME LAST_ORDERED))
      expect(interface).to_not receive(:add_merge_var)

      interface.sync_merge_vars
    end
  end

  context '#ensure_list' do
    it 'does not do much of anything useful...' do
      interface.ensure_list
    end
  end

  context '#ensure_segment' do
    it 'does nothing if the segment already exists' do
      expect(lists).to receive(:static_segments).with(list_id).and_return([{'name' => customer_segment_name, 'id' => 'xyz'}])

      interface.ensure_segment
    end

    it 'creates the segment if not found' do
      expect(lists).to receive(:static_segments).with(list_id).and_return([{'name' => 'some other segment', 'id' => '123'}])
      expect(lists).to receive(:static_segment_add).with(list_id, customer_segment_name).and_return('xyz')

      interface.ensure_segment
    end
  end
end
