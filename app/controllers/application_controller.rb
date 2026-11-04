class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "No such record in Database; check params", status: :not_found }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render json: { errors: exception.record.errors.to_hash, status: :unprocessable_entity }, status: :unprocessable_entity
  end

  rescue_from ActionController::BadRequest, ActionController::ParameterMissing,
              ActionDispatch::Http::Parameters::ParseError do
    render json: { error: "Invalid request parameters", status: :bad_request }, status: :bad_request
  end

  def catch_404
    render json: { error: "No route matches; check routes", status: :no_route }, status: :not_found
  end
end
