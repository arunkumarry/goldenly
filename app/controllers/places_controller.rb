class PlacesController < ApplicationController
  # Address lookup is available during signup before a web session exists.
  skip_before_action :require_authentication

  def autocomplete
    input = params.require(:input).to_s.strip
    return render json: { suggestions: [] } if input.length < 3

    render json: { suggestions: GooglePlaces.autocomplete(input:, session_token: session_token) }
  rescue ActionController::ParameterMissing
    render json: { error: "Enter at least three address characters." }, status: :unprocessable_content
  rescue GooglePlaces::ConfigurationError, GooglePlaces::RequestError => error
    render json: { error: error.message }, status: :service_unavailable
  end

  def show
    render json: { place: GooglePlaces.place(place_id: params.require(:place_id), session_token: session_token) }
  rescue ActionController::ParameterMissing
    render json: { error: "Choose an address suggestion." }, status: :unprocessable_content
  rescue GooglePlaces::ConfigurationError, GooglePlaces::RequestError => error
    render json: { error: error.message }, status: :service_unavailable
  end

  private

  def session_token
    token = params[:session_token].to_s
    return token if token.match?(/\A[a-zA-Z0-9_-]{12,128}\z/)

    SecureRandom.urlsafe_base64(24)
  end
end
