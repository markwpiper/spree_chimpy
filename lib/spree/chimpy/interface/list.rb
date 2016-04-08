module Spree::Chimpy
  module Interface
    class List
      delegate :log, to: Spree::Chimpy

      attr_accessor :list_name, :list_id, :customer_segment_name, :double_opt_in, :send_welcome_email

      def initialize(list_name, customer_segment_name, double_opt_in, send_welcome_email, list_id)
        @api           = Spree::Chimpy.api
        @list_id       = list_id
        @customer_segment_name  = customer_segment_name
        @double_opt_in = double_opt_in
        @send_welcome_email = send_welcome_email
        @list_name     = list_name
      end

      def api_call
        @api.lists
      end

      def subscribe(email, merge_vars = {}, options = {})
        log "Subscribing #{email} to #{@list_name}"
        ensure_list

        begin
          api_call.subscribe(list_id, { email: email }, merge_vars, 'html', @double_opt_in, true, true, @send_welcome_email)

          segment([email]) if options[:customer]
        rescue Mailchimp::ListInvalidImportError, Mailchimp::ValidationError => ex
          log "Subscriber #{email} rejected for reason: [#{ex.message}]"
          true
        end
      end

      def update_subscriber(email, merge_vars = {}, options = {})
        log "Updating subscriber #{email} for list #{@list_name}"
        ensure_list

        begin
          api_call.update_member(list_id, { email: email }, merge_vars)
        rescue Mailchimp::ListInvalidImportError,
            Mailchimp::ValidationError,
            Mailchimp::EmailNotExistsError,
            Mailchimp::ListNotSubscribedError => ex
          log "Subscriber #{email} rejected for reason: [#{ex.message}]"
          {errors: [{email: email, message: ex.message, code: ex.inspect}]}.with_indifferent_access
        end
      end

      def unsubscribe(email)
        log "Unsubscribing #{email} from #{@list_name}"
        ensure_list

        begin
          api_call.unsubscribe(list_id, { email: email })
        rescue Mailchimp::EmailNotExistsError, Mailchimp::ListNotSubscribedError
          true
        end
      end

      def info(email_or_id)
        log "Checking member info for #{email_or_id} from #{@list_name}"
        ensure_list

        #maximum of 50 emails allowed to be passed in
        response = api_call.member_info(list_id, [{email: email_or_id}])
        if response['success_count'] && response['success_count'] > 0
          record = response['data'].first.symbolize_keys
        end

        record.nil? ? {} : record
      end

      def merge_vars
        log "Finding merge vars for #{@list_name}"
        ensure_list

        api_call.merge_vars([list_id])['data'].first['merge_vars'].map {|record| record['tag']}
      end

      def add_merge_var(tag, description, options)
        log "Adding merge var #{tag} to #{@list_name}"
        ensure_list

        api_call.merge_var_add(list_id, tag, description, options)
      end

      def sync_merge_vars
        existing   = merge_vars + %w(EMAIL)
        merge_vars = Config.merge_vars.map(&:with_indifferent_access).reject { |mv| existing.member?(mv[:name]) }

        merge_vars.each do |mv|
          add_merge_var(
              mv[:name].to_s.upcase,
              (mv[:title] || mv[:accessor]).to_s.humanize.titleize,
              mv[:options] || {}
          )
        end
      end

      def find_list_id(name)
        list = @api.lists.list(list_name: name)["data"].detect { |r| r["name"] == name }
        list["id"] if list
      end

      def list_id
        @list_id ||= find_list_id(list_name)
      end

      def ensure_list
        if list_name.present?
          Rails.logger.error("spree_chimpy: hmm.. a list named `#{list_name}` was not found. Please add it and reboot the app") unless list_exists?
        end
        if list_id.present?
          Rails.logger.error("spree_chimpy: hmm.. a list with ID `#{list_id}` was not found. Please add it and reboot the app") unless list_exists?
        end
      end

      def ensure_segment
        if list_exists? && !segment_exists?
          create_segment
          Rails.logger.error("spree_chimpy: hmm.. a static segment named `#{customer_segment_name}` was not found for list #{list_name}. Creating it now")
        end
      end

      def segment(emails = [])
        log "Adding #{emails} to segment #{@customer_segment_name} [#{segment_id}] in list [#{list_id}]"
        ensure_list
        ensure_segment

        return {} if emails.empty?

        params = emails.map { |email| { email: email } }
        response = api_call.static_segment_members_add(list_id, segment_id.to_i, params)
      end

      def create_segment
        log "Creating segment #{@customer_segment_name}"
        ensure_list

        @segment_id = api_call.static_segment_add(list_id, @customer_segment_name)
      end

      def find_segment_id
        ensure_list
        segments = api_call.static_segments(list_id)
        segment  = segments.detect {|segment| segment['name'].downcase == @customer_segment_name.downcase }

        segment['id'] if segment
      end

      def segment_id
        @segment_id ||= find_segment_id
      end

      def list_exists?
        list_id.present?
      end

      def segment_exists?
        segment_id.present?
      end
    end
  end
end
