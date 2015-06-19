module Spree::Chimpy
  class Configuration
    cattr_accessor :store_id do
      'spree'
    end
    cattr_accessor :subscribed_by_default do
      false
    end
    cattr_accessor :subscribe_to_list do
      false
    end
    cattr_accessor :key do
      nil
    end
    cattr_accessor :customer_segment_name do
      'Customers'
    end
    cattr_accessor :merge_vars do
      [{ name: 'EMAIL', accessor: :email, options: {field_type: :string} }]
    end
    cattr_accessor :api_options do
      { timeout: 60 }
    end
    cattr_accessor :double_opt_in do
      false
    end
    cattr_accessor :send_welcome_email do
      true
    end
    cattr_accessor :lists_raw do
      [] #[ {name: 'Members', list_id: nil} ]
    end
    cattr_accessor :enabled do
      true
    end

    def lists=(lists)
      self.lists_raw = lists
    end

    def add_list(list)
      self.lists_raw = (self.lists_raw || []) + [list]
    end

    def lists
      lists_raw.map do |list|
        list.reverse_merge({
          subscribed_by_default: self.subscribed_by_default,
              subscribe_to_list: self.subscribe_to_list,
          customer_segment_name: self.customer_segment_name,
                     merge_vars: self.merge_vars,
                  double_opt_in: self.double_opt_in,
             send_welcome_email: self.send_welcome_email,
        }).with_indifferent_access
      end
    end
  end
end
