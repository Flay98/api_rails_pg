class Api::V1::CompaniesController < Api::V1::BaseController
  before_action :set_company, only: %i[show update destroy mark_deleted geeks applies]

  def index
    render_collection(filter_text(Company.all, :name, :location), :companies)
  end

  def show
    render_record(@company)
  end

  def create
    render_record(Company.create!(company_params), status: :created)
  end

  def update
    @company.update!(company_params)
    render_record(@company)
  end

  def destroy
    mark_deleted
  end

  def mark_deleted
    if @company.deleted?
      render json: { deleted_company: [], deleted_already: :not_modified }
    elsif @company.delete_company
      render_deleted(@company, :deleted_company)
    else
      raise ActiveRecord::RecordInvalid, @company
    end
  end

  def geeks
    render_collection(filter_text(@company.geeks, :name, :stack), :geeks)
  end

  def applies
    render_collection(filter_applies(@company.applies), :applies)
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    resource_params(:company, :name, :location)
  end
end
