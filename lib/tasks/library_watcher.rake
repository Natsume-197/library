namespace :library do
  desc "Start LibraryWatcher"
  task watch: :environment do
    LibraryWatcher.new.start
  end
end
