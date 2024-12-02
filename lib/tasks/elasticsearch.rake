namespace :elastic do
  task rebuild: :environment do
    Book.__elasticsearch__.client.indices.delete index: Book.index_name rescue nil
    Book.__elasticsearch__.create_index!
    Book.import
  end
end
