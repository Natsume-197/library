class LibraryWatcherController < ApplicationController
    def start
      watcher = LibraryWatcher.new
  
      if watcher.class.is_watcher_running
        render json: { message: "LibraryWatcher is already running." }, status: :ok
      else
        # Iniciar el proceso
        watcher.start
        render json: { message: "LibraryWatcher has started processing books." }, status: :ok
      end
    rescue StandardError => e
      render json: { error: "Failed to start LibraryWatcher: #{e.message}" }, status: :unprocessable_entity
    end
  end
  