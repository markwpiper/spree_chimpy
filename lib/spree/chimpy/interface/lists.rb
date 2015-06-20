module Spree::Chimpy
  module Interface
    class Lists

      delegate :log, to: Spree::Chimpy

      def self.delegate_each(*methods)
        options = methods.pop
        unless options.is_a?(Hash) && to = options[:to]
          raise ArgumentError, 'Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate :hello, to: :greeter).'
        end

        prefix, allow_nil = options.values_at(:prefix, :allow_nil)

        if prefix == true && to =~ /^[^a-z_]/
          raise ArgumentError, 'Can only automatically set the delegation prefix when delegating to a method.'
        end

        method_prefix = \
            if prefix
              "#{prefix == true ? to : prefix}_"
            else
              ''
            end

        file, line = caller.first.split(':', 2)
        line = line.to_i

        to = to.to_s
        to = 'self.class' if to == 'class'

        methods.each do |method|
          # Attribute writer methods only accept one argument. Makes sure []=
          # methods still accept two arguments.
          definition = (method =~ /[^\]]=$/) ? 'arg' : '*args, &block'

          # The following generated methods call the target exactly once, storing
          # the returned value in a dummy variable.
          #
          # Reason is twofold: On one hand doing less calls is in general better.
          # On the other hand it could be that the target has side-effects,
          # whereas conceptualy, from the user point of view, the delegator should
          # be doing one call.
          if allow_nil
            module_eval(<<-EOS, file, line - 3)
          def #{method_prefix}#{method}(#{definition})        # def customer_name(*args, &block)
            #{to}.map do |_|                                  #   client.each do |_|
              if !_.nil? || nil.respond_to?(:#{method})       #     if !_.nil? || nil.respond_to?(:name)
                _.#{method}(#{definition})                    #       _.name(*args, &block)
              end                                             #     end
            end                                               #   end
          end                                                 # end
            EOS
          else
            exception = %(raise "#{self}##{method_prefix}#{method} delegated to #{to}.#{method}, but #{to} is nil: \#{self.inspect}")

            module_eval(<<-EOS, file, line - 2)
          def #{method_prefix}#{method}(#{definition})                                              # def customer_name(*args, &block)
            #{to}.map do |_|                                                                        #   client.each do |_|
              begin                                                                                 #     begin
                _.#{method}(#{definition})                                                          #       _.name(*args, &block)
              rescue NoMethodError => e                                                             #     rescue NoMethodError => e
                location = "%s:%d:in `%s'" % [__FILE__, __LINE__ - 2, '#{method_prefix}#{method}']  #       location = "%s:%d:in `%s'" % [__FILE__, __LINE__ - 2, 'customer_name']
                if _.nil? && e.backtrace.first == location                                          #       if _.nil? && e.backtrace.first == location
                  #{exception}                                                                      #         # add helpful message to the exception
                else                                                                                #       else
                  raise                                                                             #         raise
                end                                                                                 #       end
              end                                                                                   #     end
            end                                                                                     #   end
          end                                                                                       # end
            EOS
          end
        end
      end

      attr_accessor :lists

      def initialize(lists)
        @lists = lists
      end

      delegate_each :subscribe, to: :lists
      delegate_each :unsubscribe, to: :lists
      delegate_each :update_subscriber, to: :lists
      delegate_each :add_merge_var, to: :lists
      delegate_each :create_segment, to: :lists
      delegate_each :sync_merge_vars, to: :lists
      delegate_each :segment, to: :lists
      delegate_each :ensure_list, to: :lists
      delegate_each :ensure_segment, to: :lists

      def info(email_or_id)
        ## return info from the first list which returns non-nil result
        ## TODO: only call subsequent lists if first list returns nil/empty
        lists.map { |list| list.info(email_or_id) }.reject(&:nil?).reject(&:empty?).first
      end
    end
  end
end
