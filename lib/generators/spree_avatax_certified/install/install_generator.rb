module SpreeAvatax
  module Generators
    class InstallGenerator < Rails::Generators::Base

      def add_javascripts
        append_file 'vendor/assets/javascripts/spree/frontend/all.js', "//= require spree/frontend/spree_avatax_certified\n"
        append_file 'vendor/assets/javascripts/spree/backend/all.js', "//= require spree/backend/spree_avatax_certified\n"
      end

      def add_stylesheets
        inject_into_file 'vendor/assets/stylesheets/spree/frontend/all.css', " *= require spree/frontend/spree_avatax_certified\n", :before => /\*\//, :verbose => true
        inject_into_file 'vendor/assets/stylesheets/spree/backend/all.css', " *= require spree/backend/spree_avatax_certified\n", :before => /\*\//, :verbose => true
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_avatax_certified'
      end

      def run_migrations
        res = ask 'Would you like to run the migrations now? [Y/n]'
        if res == '' || res.downcase == 'y'
          run 'bundle exec rake db:migrate'
          puts "Loading Use Code data..."
          # use_code_seeds
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end

      # def use_code_seeds

      #   use_codes = {
      #     "A" => "Federal government",
      #     "B" => "State government",
      #     "C" => "Tribe/Status Indian/Indian Band",
      #     "D" => "Foreign diplomat",
      #     "E" => "Charitable or benevolent organization",
      #     "F" => "Religious or educational organization",
      #     "G" => "Resale",
      #     "H" => "Commercial agricultural production",
      #     "I" => "Industrial production/manufacturer",
      #     "J" => "Direct pay permit",
      #     "K" => "Direct mail",
      #     "L" => "Other",
      #     "N" => "Local government",
      #     "P" => "Commercial aquaculture (Canada only)",
      #     "Q" => "Commercial fishery (Canada only)",
      #     "R" => "Non-resident (Canada only)"
      #   }
      #   unless Spree::AvalaraUseCodeItem.count >= 16
      #     use_codes.each do |key, value|
      #       Spree::AvalaraUseCodeItem.create(use_code: key, use_code_description: value)
      #     end
      #     Spree::Config.avatax_origin = {}
      #   end
      # end
    end
  end
end
