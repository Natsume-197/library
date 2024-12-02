class BooksController < ApplicationController
  def index
    query = params[:query].presence || '*'

    author_filter = params[:author_eng].presence
    title_filter = params[:title_jp].presence

    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = 100

    @results = Book.search_books(
      query,
      author: author_filter,
      title: title_filter,
      page: page,
      per_page: per_page
    )

    @books = @results.map do |result|
      {
        id: result[:id],
        title: result[:title],
        author: result[:author],
        score: result[:score],
        path_image: result[:path_image],
        path_download: result[:path_download],
        highlighted_title: result[:highlighted_title],
        highlighted_title_readingform: result[:highlighted_title_readingform],
        highlighted_author: result[:highlighted_author],
        filesize: result[:filesize],
        filetype: result[:filetype],
        source: result[:source]
      }
    end

    @total = @books.size
    @total_pages = (@total / per_page.to_f).ceil

    respond_to do |format|
      format.html
      format.js
    end
  end

  def download
    book = Book.find(params[:id])

    if book.path_download.present?
      library_path = Rails.root.join('app', 'library')
      absolute_path = File.expand_path(book.path_download, library_path)

      if File.exist?(absolute_path)
        send_file(
          absolute_path,
          filename: File.basename(absolute_path),
          type: "application/epub+zip"
        )
      else
        render plain: "File not found", status: :not_found
      end
    else
      render plain: "File not found", status: :not_found
    end
  end
end