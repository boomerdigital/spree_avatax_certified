require 'spree_avatax_certified/seeder'

namespace :spree_avatax_certified do
  task :load_seeds do
    SpreeAvataxCertified::Seeder.seed!
  end
end
