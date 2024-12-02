class CoversController < ApplicationController
    def show
      cover_path = Rails.root.join('app', 'library', params[:path])
  
      if valid_image_path?(cover_path)
        send_file cover_path, disposition: 'inline'
      else
        render plain: 'Cover not found', status: :not_found
      end
    end
  
    private
  
    def valid_image_path?(path)
      File.exist?(path) &&
        ['.jpg', '.jpeg', '.png', '.gif'].include?(File.extname(path).downcase) &&
        path.to_s.start_with?(Rails.root.join('app', 'library').to_s)
    end
  end
  