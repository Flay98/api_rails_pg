class Api::V1::JobsController < Api::V1::BaseController
  before_action :set_company
  before_action :set_job, only: %i[show update destroy geeks]

  def index
    render_collection(filter_text(job_scope, :name, :place), :jobs)
  end

  def show
    render_record(@job)
  end

  def create
    attributes = job_params
    attributes[:company_id] = @company.id if @company
    render_record(Job.create!(attributes), status: :created)
  end

  def update
    attributes = job_params
    attributes[:company_id] = @company.id if @company
    @job.update!(attributes)
    render_record(@job)
  end

  def destroy
    if @job.deleted?
      render json: { deleted_job: [], deleted_already: :not_modified }
    elsif @job.delete_job
      render_deleted(@job, :deleted_job)
    else
      raise ActiveRecord::RecordInvalid, @job
    end
  end

  def geeks
    render_collection(filter_text(@job.geeks, :name, :stack), :geeks)
  end

  private

  def set_company
    company_id = request.path_parameters[:company_id]
    @company = Company.find(company_id) if company_id
  end

  def job_scope
    @company ? @company.jobs : Job.all
  end

  def set_job
    @job = job_scope.find(params[:id])
  end

  def job_params
    resource_params(:job, :name, :place, :company_id)
  end
end
