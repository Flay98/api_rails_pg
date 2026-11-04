class Api::V1::BaseController < ApplicationController
  # Parse flat and wrapped payloads explicitly, including invalid empty bodies.
  wrap_parameters false

  private

  def render_record(record, status: :ok)
    render json: serializer_for(record).serialize(record), status: status
  end

  def render_collection(records, key)
    render json: { key => records.order(:id).map { |record| serializer_for(record).serialize(record) } }
  end

  def serializer_for(record)
    "#{record.class.name}Serializer".constantize
  end

  def resource_params(key, *attributes)
    source = params.key?(key) ? params.require(key) : params
    raise ActionController::BadRequest unless source.is_a?(ActionController::Parameters)

    source.permit(*attributes)
  end

  def filter_text(records, *attributes)
    attributes.each do |attribute|
      next if params[attribute].blank?
      raise ActionController::BadRequest unless params[attribute].is_a?(String)

      value = ActiveRecord::Base.sanitize_sql_like(params[attribute])
      records = records.where(records.klass.arel_table[attribute].matches("%#{value}%"))
    end
    records
  end

  def filter_applies(records)
    %i[read invited].each do |attribute|
      next unless params.key?(attribute)
      raise ActionController::BadRequest unless Apply::BOOLEAN_VALUES.include?(params[attribute])

      records = records.where(attribute => ActiveModel::Type::Boolean.new.cast(params[attribute]))
    end
    records
  end

  def render_deleted(record, key)
    render json: { key => serializer_for(record).serialize(record), code: 200, status: :success }
  end
end
