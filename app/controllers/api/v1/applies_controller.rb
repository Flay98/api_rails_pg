class Api::V1::AppliesController < Api::V1::BaseController
  before_action :set_apply, only: %i[show update destroy mark_read invite]

  def index
    records = Apply.all
    records = records.where(job_id: find_job.id) if params[:job_id]
    records = records.where(geek_id: Geek.find(params[:geek_id]).id) if params[:geek_id]
    render_collection(filter_applies(records), :applies)
  end

  def show
    render_record(@apply)
  end

  def create
    render_record(Apply.create!(apply_params), status: :created)
  end

  def update
    @apply.update!(apply_params)
    render_record(@apply)
  end

  def destroy
    @apply.destroy!
    render_deleted(@apply, :deleted_apply)
  end

  def mark_read
    @apply.update!(read: true)
    render_record(@apply)
  end

  def invite
    @apply.update!(invited: true)
    render_record(@apply)
  end

  private

  def set_apply
    @apply = Apply.find(params[:id])
  end

  def find_job
    scope = params[:company_id] ? Company.find(params[:company_id]).jobs : Job.all
    scope.find(params[:job_id])
  end

  def apply_params
    resource_params(:apply, :job_id, :geek_id, :read, :invited)
  end
end
