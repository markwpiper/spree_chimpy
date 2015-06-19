module Spree::Chimpy
  class Subscription
    delegate :configured?, :enqueue, to: Spree::Chimpy

    def initialize(model)
      @model      = model
    end

    def subscribe
      return unless configured?
      defer(:subscribe) if subscribing?
    end

    def unsubscribe
      return unless configured?
      defer(:unsubscribe) if unsubscribing?
    end

    def resubscribe(&block)
      block.call if block

      return unless configured?

      if unsubscribing?
        defer(:unsubscribe)
      elsif subscribing?
        defer(:subscribe)
      elsif merge_vars_changed?
        defer(:update_subscriber)
      end
    end

    def subscribing?
      @model.subscribed && (@model.subscribed_changed? || @model.id_changed? || @model.new_record?)
    end

    def unsubscribing?
      !@model.new_record? && !@model.subscribed && @model.subscribed_changed?
    end

    def merge_vars_changed?
      Config.merge_vars.map(&:with_indifferent_access).any? do |mv|
        accessor = mv[:accessor]
        change_accessor = "#{accessor}_changed?".to_sym
        !@model.methods.include?(change_accessor) || @model.send(change_accessor)
      end
    end

  private
    def defer(event)
      enqueue(event, @model)
    end
  end
end
