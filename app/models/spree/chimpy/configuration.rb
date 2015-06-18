module Spree::Chimpy
  class Configuration < Spree::Preferences::Configuration
    preference :store_id,              :string,  default: 'spree'
    preference :subscribed_by_default, :boolean, default: false
    preference :subscribe_to_list,     :boolean, default: false
    preference :key,                   :string
    preference :customer_segment_name, :string,  default: 'Customers'
    preference :merge_vars,            :hash,    default: { 'EMAIL' => :email }
    preference :api_options,           :hash,    default: { timeout: 60 }
    preference :double_opt_in,         :boolean, default: false
    preference :send_welcome_email,    :boolean, default: true
    preference :lists_raw,             :array,   default: [] #[ {name: 'Members', list_id: nil} ]
    preference :enabled,               :boolean, default: false

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
