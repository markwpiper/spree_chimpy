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
      delegate_each :add_merge_var, to: :lists
      delegate_each :create_segment, to: :lists

      def sync_merge_vars
        lists.each do |list|
          existing   = list.merge_vars + %w(EMAIL)
          merge_vars = Config.merge_vars.except(*existing)

          merge_vars.each do |tag, method|
            list.add_merge_var(tag.upcase, method.to_s.humanize.titleize)
          end
        end
      end

      def ensure_lists
        lists.each do |list|
          if list.list_name.present?
            Rails.logger.error("spree_chimpy: hmm.. a list named `#{list.name}` was not found. Please add it and reboot the app") unless list_exists?(list)
          end
          if list.list_id.present?
            Rails.logger.error("spree_chimpy: hmm.. a list with ID `#{list.list_id}` was not found. Please add it and reboot the app") unless list_exists?(list)
          end
        end
      end

      def ensure_segments
        lists.each do |list|
          if list_exists?(list) && !segment_exists?(list)
            create_segment(list)
            Rails.logger.error("spree_chimpy: hmm.. a static segment named `#{list.customer_segment_name}` was not found. Creating it now")
          end
        end
      end

      def list_exists?(list)
        list.list_id
      end

      def segment_exists?(list)
        list.segment_id
      end

      def create_segment(list)
        list.create_segment
      end

      def segment(emails = [])
        lists.map do |list|
          list.segment(emails)
        end
      end

      # def info(email_or_id)
      # def merge_vars
      # def find_list_id(name)
      # def list_id
      # def find_segment_id
      # def segment_id
    end
  end
end
