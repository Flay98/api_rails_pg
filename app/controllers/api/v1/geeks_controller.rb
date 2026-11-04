class Api::V1::GeeksController < Api::V1::BaseController
  before_action :set_geek, only: %i[show update destroy resume read_applies invited_applies]

  def index
    render_collection(filter_text(Geek.all, :name, :stack), :geeks)
  end

  def show
    render_record(@geek)
  end

  def create
    render_record(Geek.create!(geek_params), status: :created)
  end

  def update
    @geek.update!(geek_params)
    render_record(@geek)
  end

  def destroy
    @geek.destroy!
    render_deleted(@geek, :deleted_geek)
  end

  def resume
    @geek.update!(resource_params(:geek, :resume))
    render_record(@geek)
  end

  def read_applies
    render_collection(filter_applies(@geek.applies.where(read: true)), :applies)
  end

  def invited_applies
    render_collection(filter_applies(@geek.applies.where(invited: true)), :applies)
  end

  private

  def set_geek
    @geek = Geek.find(params[:id])
  end

  def geek_params
    resource_params(:geek, :name, :stack, :resume)
  end
end
