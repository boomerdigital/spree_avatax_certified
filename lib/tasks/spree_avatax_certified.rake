namespace :spree_avatax_certified do
  task :load_seeds => :environment do
    SpreeAvataxCertified::Seeder.seed!
  end

  task :commit_orders, [:path] => [:environment] do |t, args|
    SmarterCSV.process("#{Rails.root}/tmp/#{args[:path]}").each do |chunk|
      begin
        order = Spree::Order.find_by_number(chunk[:doccode]).avalara_capture_finalize
      rescue => e
        puts "COMMIT ORDERS ERROR: #{e}: #{order.number}"
      end
    end
  end
end
