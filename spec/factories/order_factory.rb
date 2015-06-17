FactoryGirl.define do
  factory :order_with_line_item_quantity, parent: :order do
    transient do
      line_items_quantity 1
    end

    after(:create) do |order, evaluator|
      create(:line_item, order: order, price: evaluator.line_items_price, quantity: evaluator.line_items_quantity)
      order.line_items.reload # to ensure order.line_items is accessible after
    end
  end

  factory :completed_order_with_pending_payment, parent: :completed_order_with_totals do
    after(:create) do |order|
      create(:payment, amount: order.total, order: order)
    end
  end
end