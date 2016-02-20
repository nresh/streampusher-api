class PlaylistsController < ApplicationController
  load_and_authorize_resource
  def show
    @tracks = @current_radio.tracks
    @playlist = Playlist.find params[:id]
  end
  def index
    @tracks = @current_radio.tracks
    @playlists = @current_radio.playlists
    @playlist = Playlist.new
  end

  def create
    @playlist = @current_radio.playlists.new create_params
    if @playlist.save
      ActiveSupport::Notifications.instrument 'playlist.created', current_user: current_user.email, radio: @current_radio.name, playlist: @playlist.name
      flash[:notice] = "created playlist"
      render 'create'
    else
      flash[:error] = "couldn't create playlist"
      render 'error'
    end
  end

  def edit
    @playlist = @current_radio.playlists.find params[:id]
  end

  def update
    @playlist = @current_radio.playlists.find params[:id]
    @playlist.attributes = update_params
    if @playlist.save
      flash[:notice] = "updated playlist"
      render "update"
    else
      flash[:error] = 'error updating playlist :('
      render 'edit'
    end
  end

  def update_order
    @playlist_track = PlaylistTrack.find(playlist_track_params[:playlist_track_id])
    @playlist_track.position = playlist_track_params[:position]
    @playlist_track.save

    render nothing: true # this is a POST action, updates sent via AJAX, no view rendered
  end

  private
  def playlist_track_params
    params.require(:playlist_track).permit(:playlist_track_id, :position)
  end

  def create_params
    params.require(:playlist).permit(:name, :radio_id)
  end

  def update_params
    params.require(:playlist).permit(:name, :interpolated_playlist_id,
                                     :interpolated_playlist_track_play_count,
                                     :interpolated_playlist_track_interval_count,
                                     :interpolated_playlist_enabled)
  end
end
