namespace :spree_chimpy do
  namespace :merge_vars do
    desc 'sync merge vars with mail chimp'
    task sync: :environment do
      Spree::Chimpy.sync_merge_vars
    end
  end

  namespace :orders do
    desc 'sync all orders with mail chimp'
    task sync: :environment do
      scope = Spree::Order.complete

      puts "Exporting #{scope.count} orders"

      scope.find_in_batches do |batch|
        print '.'
        batch.each do |order|
          begin
            order.notify_mail_chimp
          rescue => exception
            if defined?(::Delayed::Job)
              raise exception
            else
              puts exception
            end
          end
        end
      end

      puts nil, 'done'
    end
  end

  namespace :users do
    desc 'segment all subscribed users'
    task segment: :environment do
      Spree::Chimpy.ensure_segment

      emails = Spree.user_class.where(subscribed: true).pluck(:email)
      puts "Segmenting all subscribed users"
      responses = Spree::Chimpy.list.segment(emails)
      responses.each do |response|
        response["errors"].try :each do |error|
          puts "Error #{error["code"]} with email: #{error["email"]} \n msg: #{error["msg"]}"
        end
        puts "segmented #{response["success"] || 0} out of #{emails.size}"
      end
      puts "done"
    end

    desc 'sync merge-vars for all subscribed users'
    task sync: :environment do
      emails = Spree.user_class.find_each do |user|
        responses = Spree::Chimpy.list.update_subscriber(user.email, Spree::Chimpy.merge_vars(user), customer: true)
        responses.each do |response|
          response["errors"].try :each do |error|
            puts "Error #{error["code"]} with email: #{error["email"]} \n msg: #{error["msg"]}"
          end
        end
      end
      puts "done"
    end
  end

  desc 'sync all users subscribed state from mailchimp'
  task sync: :environment do
    emails = Spree.user_class.pluck(:email)
    puts "Syncing all users"
    emails.each do |email|
      response = Spree::Chimpy.list.info(email)
      print '.'

      response["errors"].try :each do |error|
        puts "Error #{error['error']["code"]} with email: #{error['email']["email"]} \n
              msg: #{error["error"]}"
      end

      case response[:status]
      when "subscribed"
        Spree.user_class.where(email: email).update_all(subscribed: true)
      when "unsubscribed"
        Spree.user_class.where(email: email).update_all(subscribed: false)
      end
    end
  end
end
