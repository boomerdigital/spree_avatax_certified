namespace :spree_avatax_certified do
  desc "Loads seed data."
  task load_seeds: :environment do
    SpreeAvataxCertified::Seeder.seed!
  end
end
