require 'database_cleaner'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    # if example.metadata[:js]
      DatabaseCleaner.strategy = :truncation
    # else
  end
  config.before(:each, js: false) do |example|
    DatabaseCleaner.start
  end

  config.after(:each) do |example|
    DatabaseCleaner.clean
  end

  config.after(:each, js: true) do |example|
    # if example.metadata[:js]
      DatabaseCleaner.strategy = :transaction
    # end
  end
end
