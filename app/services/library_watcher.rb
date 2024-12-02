require 'listen'
require 'epub/parser'
require 'dotenv/load'
require 'mime/types'

class LibraryWatcher
  def initialize
    @library_path = Rails.root.join('app', 'library')
    Rails.logger.info "LibraryWatcher initialized. Path: #{@library_path}"
  end

  def start
    Rails.logger.info "Processing existing files..."
    process_existing_files

    Rails.logger.info "Starting listener for new files..."
    listener = Listen.to(@library_path, only: /\.epub$/i, force_polling: true) do |added, _modified, _removed|
      added.each do |file_path|
        Rails.logger.info "Detected new file: #{file_path}"
        process_epub(file_path)
      end
    end

    listener.start
    Rails.logger.info "LibraryWatcher is now monitoring #{@library_path}."
    loop do
      Rails.logger.info "LibraryWatcher is active. Monitoring for changes... (#{Time.now})"
      sleep 10
    end
  end

  private

  def process_existing_files
    Rails.logger.info "Scanning existing files in #{@library_path}..."
    Dir.glob(File.join(@library_path, '**', '*.epub')).each do |file_path|
      Rails.logger.info "Processing existing file: #{file_path}"
      process_epub(file_path)
    end
  end

  def process_epub(file_path)
    Rails.logger.info "Starting processing for: #{file_path}"
    epub = EPUB::Parser.parse(file_path)
    Rails.logger.info "Parsed EPUB metadata for: #{file_path}"

    title_jp = extract_japanese_title(epub)
    author_jp = extract_author(epub)

    cover_url = save_cover_image(epub, file_path)

    relative_path = Pathname.new(file_path).relative_path_from(@library_path).to_s
    source, name_folder = relative_path.split(File::SEPARATOR).first(2)
    
    file_size = File.size(file_path)
    mime_type = MIME::Types.type_for(file_path).first.content_type

    if Book.exists?(title_jp: title_jp, author_jp: author_jp)
      Rails.logger.info "Book already exists with same title and author: #{title_jp} by #{author_jp}"
      return
    end

    unless Book.exists?(path_download: file_path)
      Book.create(
        title_jp: title_jp,
        author_jp: author_jp,
        path_download: relative_path,
        path_image: cover_url,
        source: source,
        filesize: file_size,
        filetype: mime_type
      )

      Rails.logger.info "Book created: #{title_jp} (#{file_path})"
    else
      Rails.logger.info "Book already exists: #{title_jp} (#{file_path})"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to process file: #{file_path}. Error: #{e.message}"
  end

  def extract_title(epub)
    epub.metadata.title || "Unknown Title"
  end

  def extract_japanese_title(epub)
    epub.metadata.title || "Unknown Japanese Title"
  end
  
  def extract_author(epub)
    author = epub.metadata.creators&.first&.content
    author.presence || "Unknown Author"
  end

  def save_cover_image(epub, file_path)
    cover_item = epub.manifest.items.find { |item| item.properties.include?('cover-image') }
    cover_item ||= epub.manifest.items.find { |item| item.media_type.start_with?('image/') }
  
    return nil unless cover_item
  
    cover_data = cover_item.read
    return nil unless cover_data
  
    # Save the cover in public/covers/<source>/<name-folder>/<unique-cover-name>.jpg
    relative_path = Pathname.new(file_path).relative_path_from(@library_path).to_s
    source, name_folder = relative_path.split(File::SEPARATOR).first(2)
    public_cover_dir = Rails.root.join('public', 'covers', source, name_folder)
    FileUtils.mkdir_p(public_cover_dir)
  
    cover_filename = "#{File.basename(file_path, '.epub')}_cover.jpg"
    cover_path = File.join(public_cover_dir, cover_filename)
  
    File.open(cover_path, 'wb') do |file|
      file.write(cover_data)
    end
  
    File.join('/covers', source, name_folder, cover_filename)
  rescue StandardError => e
    Rails.logger.error "Failed to save cover image: #{file_path}. Error: #{e.message}"
    nil
  end
  
end
