require "test_helper"

class ApiTest < ActionDispatch::IntegrationTest
  setup do
    @company = Company.create!(name: "MoGo", location: "New York")
    @other_company = Company.create!(name: "BuildEmpire", location: "London")
    @job = @company.jobs.create!(name: "Sinatra React", place: "Remote")
    @other_job = @other_company.jobs.create!(name: "Ruby on Rails", place: "Contract")
    @geek = Geek.create!(name: "Mike", stack: "Ruby React")
    @other_geek = Geek.create!(name: "Alex", stack: "Rails")
    @apply = Apply.create!(job: @job, geek: @geek)
    @invited = Apply.create!(job: @other_job, geek: @geek, read: true, invited: true)
    @rejected = Apply.create!(job: @job, geek: @other_geek, read: true, invited: false)
  end

  test "all resources can be listed and shown with explicit JSON fields" do
    { companies: @company, jobs: @job, geeks: @geek, applies: @apply }.each do |resource, record|
      get "/v1/#{resource}"
      assert_response :ok
      assert_equal "application/json", response.media_type
      assert_includes json.fetch(resource.to_s).pluck("id"), record.id
      get "/v1/#{resource}/#{record.id}"
      assert_response :ok
      assert_equal record.id, json.fetch("id")
      assert_not json.key?("created_at")
      assert_not json.key?("updated_at")
    end
  end

  test "companies filter by partial case insensitive name and location with AND" do
    get "/v1/companies", params: { name: "mOg", location: "york" }
    assert_response :ok
    assert_equal [ @company.id ], ids(:companies)
    get "/v1/companies", params: { name: "MoGo", location: "London" }
    assert_empty ids(:companies)
  end

  test "jobs filter by name and place" do
    get "/v1/jobs", params: { name: "react", place: "remote" }
    assert_response :ok
    assert_equal [ @job.id ], ids(:jobs)
  end

  test "geeks filter by name and stack" do
    get "/v1/geeks", params: { name: "ik", stack: "ruby" }
    assert_response :ok
    assert_equal [ @geek.id ], ids(:geeks)
  end

  test "filter wildcard characters are treated literally" do
    get "/v1/companies", params: { name: "%" }
    assert_response :ok
    assert_empty ids(:companies)
    get "/v1/jobs", params: { name: "' OR 1=1 --" }
    assert_response :ok
    assert_empty ids(:jobs)
  end

  test "applications filter both true and false statuses" do
    [ true, false ].each do |read|
      [ true, false ].each do |invited|
        get "/v1/applies", params: { read: read, invited: invited }
        assert_response :ok
        expected = Apply.where(read: read, invited: invited).order(:id).ids
        assert_equal expected, ids(:applies)
      end
    end
  end

  test "invalid filters return a JSON bad request" do
    [ [ "/v1/applies", { read: "banana" } ],
      [ "/v1/applies", { invited: "" } ],
      [ "/v1/jobs", { name: [ "Ruby" ] } ] ].each do |path, params|
      get path, params: params
      assert_response :bad_request
      assert_equal "bad_request", json.fetch("status")
    end
  end

  test "creates all resources with flat or wrapped JSON" do
    post "/v1/companies", params: { name: "Malta", location: "Minsk" }, as: :json
    assert_response :created
    company_id = json.fetch("id")
    post "/v1/jobs", params: { job: { name: "JS Angular", place: "Tomsk", company_id: company_id } }, as: :json
    assert_response :created
    job_id = json.fetch("id")
    post "/v1/geeks", params: { name: "Nina", stack: "Node", resume: "Node developer" }, as: :json
    assert_response :created
    geek_id = json.fetch("id")
    post "/v1/applies", params: { job_id: job_id, geek_id: geek_id }, as: :json
    assert_response :created
    assert_equal false, json.fetch("read")
    assert_equal false, json.fetch("invited")
  end

  test "POST query parameters from the manual are accepted" do
    post "/v1/jobs?name=JS%20Angular&place=Tomsk&company_id=#{@company.id}"
    assert_response :created
    assert_equal "JS Angular", json.fetch("name")
  end

  test "a top level update can move a job to another valid company" do
    put "/v1/jobs/#{@job.id}", params: { company_id: @other_company.id }, as: :json
    assert_response :ok
    assert_equal @other_company.id, @job.reload.company_id
    post "/v1/jobs", params: { name: "Rails", place: "Remote", company_id: 2_000_000_000 }, as: :json
    assert_response :unprocessable_entity
  end

  test "all resources can be updated with PUT and PATCH" do
    [ :put, :patch ].each do |verb|
      { companies: [ @company, { location: "Minsk" } ],
        jobs: [ @job, { place: "Tomsk" } ],
        geeks: [ @geek, { stack: "Rails" } ],
        applies: [ @apply, { read: true, invited: true } ] }.each do |resource, (record, attributes)|
        public_send(verb, "/v1/#{resource}/#{record.id}", params: attributes, as: :json)
        assert_response :ok
        attributes.each { |key, value| assert_equal value, record.reload.public_send(key) }
      end
    end
  end

  test "all resources reject invalid creates without saving" do
    { companies: Company, jobs: Job, geeks: Geek, applies: Apply }.each do |resource, model|
      assert_no_difference "#{model}.count" do
        post "/v1/#{resource}", params: { name: "" }, as: :json
      end
      assert_response :unprocessable_entity
      assert json.fetch("errors").present?
    end
  end

  test "invalid updates do not change any resource" do
    { companies: [ @company, { name: "" } ], jobs: [ @job, { company_id: 2_000_000_000 } ],
      geeks: [ @geek, { stack: "" } ], applies: [ @apply, { read: nil } ] }.each do |resource, (record, attributes)|
      original = record.attributes
      put "/v1/#{resource}/#{record.id}", params: attributes, as: :json
      assert_response :unprocessable_entity
      assert_equal original, record.reload.attributes
    end
  end

  test "applications reject nonexistent relations and invalid boolean text" do
    [ { job_id: 2_000_000_000, geek_id: @geek.id },
      { job_id: @job.id, geek_id: 2_000_000_000 },
      { job_id: @job.id, geek_id: @geek.id, invited: "yes" } ].each do |attributes|
      post "/v1/applies", params: attributes, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "strong parameters prevent overwriting ids and deletion flags" do
    put "/v1/companies/#{@company.id}", params: { id: 123, deleted: true, location: "London" }, as: :json
    assert_response :ok
    assert_equal false, @company.reload.deleted
    assert_equal @company.id, json.fetch("id")
    put "/v1/jobs/#{@job.id}", params: { deleted: true }, as: :json
    assert_response :ok
    assert_equal false, @job.reload.deleted
  end

  test "nested jobs implement CRUD and keep the route company" do
    base = "/v1/companies/#{@company.id}/jobs"
    get base
    assert_response :ok
    assert_equal [ @job.id ], ids(:jobs)
    post base, params: { name: "Node", place: "Permanent", company_id: @other_company.id }, as: :json
    assert_response :created
    job_id = json.fetch("id")
    assert_equal @company.id, json.fetch("company_id")
    get "#{base}/#{job_id}"
    assert_response :ok
    [ :put, :patch ].each do |verb|
      public_send(verb, "#{base}/#{job_id}", params: { place: "Remote", company_id: @other_company.id }, as: :json)
      assert_response :ok
      assert_equal @company.id, json.fetch("company_id")
    end
    delete "#{base}/#{job_id}"
    assert_response :ok
    assert Job.find(job_id).deleted?
  end

  test "nested routes cannot access jobs of another company" do
    path = "/v1/companies/#{@company.id}/jobs/#{@other_job.id}"
    [ :get, :put, :patch, :delete ].each do |verb|
      public_send(verb, path, params: { place: "Changed" }, as: :json)
      assert_response :not_found
    end
    [ "geeks", "applies" ].each do |suffix|
      get "#{path}/#{suffix}"
      assert_response :not_found
    end
    assert_equal "Contract", @other_job.reload.place
    assert_not @other_job.deleted?
  end

  test "lists applicants of a job and company without duplicates" do
    Apply.create!(job: @job, geek: @geek)
    [ "/v1/jobs/#{@job.id}/geeks", "/v1/companies/#{@company.id}/jobs/#{@job.id}/geeks",
      "/v1/companies/#{@company.id}/geeks" ].each do |path|
      get path
      assert_response :ok
      assert_equal [ @geek.id, @other_geek.id ].sort, ids(:geeks).sort
    end
  end

  test "lists applications by company job and geek" do
    { "/v1/jobs/#{@job.id}/applies" => [ @apply.id, @rejected.id ],
      "/v1/companies/#{@company.id}/jobs/#{@job.id}/applies" => [ @apply.id, @rejected.id ],
      "/v1/companies/#{@company.id}/applies" => [ @apply.id, @rejected.id ],
      "/v1/geeks/#{@geek.id}/applies" => [ @apply.id, @invited.id ] }.each do |path, expected|
      get path
      assert_response :ok
      assert_equal expected.sort, ids(:applies).sort
    end
    get "/v1/jobs/#{@job.id}/applies", params: { read: false }
    assert_equal [ @apply.id ], ids(:applies)
  end

  test "lists read applications and invitations of one geek" do
    %w[read_applies invited_applies].each do |action|
      get "/v1/geeks/#{@geek.id}/#{action}"
      assert_response :ok
      assert_equal [ @invited.id ], ids(:applies)
    end
  end

  test "adds and clears resume without changing other fields" do
    put "/v1/geeks/#{@geek.id}/resume", params: { resume: "Ruby developer", name: "Changed" }, as: :json
    assert_response :ok
    assert_equal "Ruby developer", @geek.reload.resume
    assert_equal "Mike", @geek.name
    put "/v1/geeks/#{@geek.id}/resume", params: { geek: { resume: nil } }, as: :json
    assert_response :ok
    assert_nil @geek.reload.resume
  end

  test "marks an application read invites and then rejects it" do
    put "/v1/applies/#{@apply.id}/mark_read"
    assert_response :ok
    assert @apply.reload.read?
    assert_not @apply.invited?
    put "/v1/applies/#{@apply.id}/invite"
    assert_response :ok
    assert @apply.reload.invited?
    put "/v1/applies/#{@apply.id}", params: { invited: false }, as: :json
    assert_response :ok
    assert_not @apply.reload.invited?
  end

  test "DELETE company and mark_deleted preserve all related data and handle repeats" do
    [ :delete, :put ].each do |verb|
      @company.update!(deleted: false)
      path = "/v1/companies/#{@company.id}"
      path += "/mark_deleted" if verb == :put
      assert_no_difference [ "Company.count", "Job.count", "Apply.count" ] do
        public_send(verb, path)
      end
      assert_response :ok
      assert_equal true, json.fetch("deleted_company").fetch("deleted")
      public_send(verb, path)
      assert_response :ok
      assert_equal "not_modified", json.fetch("deleted_already")
      assert @company.reload.deleted?
      assert Job.exists?(@job.id)
      assert Apply.exists?(@apply.id)
    end
  end

  test "DELETE job preserves the job and its applications and handles repeats" do
    assert_no_difference [ "Job.count", "Apply.count" ] do
      delete "/v1/jobs/#{@job.id}"
    end
    assert_response :ok
    assert @job.reload.deleted?
    delete "/v1/jobs/#{@job.id}"
    assert_response :ok
    assert_equal "not_modified", json.fetch("deleted_already")
  end

  test "marked records remain accessible with a deleted flag as in chapter seven" do
    @company.delete_company
    @job.delete_job
    { companies: @company, jobs: @job }.each do |resource, record|
      get "/v1/#{resource}/#{record.id}"
      assert_response :ok
      assert_equal true, json.fetch("deleted")
      get "/v1/#{resource}"
      assert_response :ok
      assert_equal true, json.fetch(resource.to_s).find { |item| item.fetch("id") == record.id }.fetch("deleted")
    end
  end

  test "DELETE application and geek physically deletes them" do
    assert_difference "Apply.count", -1 do
      delete "/v1/applies/#{@apply.id}"
    end
    assert_response :ok
    assert_equal @apply.id, json.fetch("deleted_apply").fetch("id")
    assert_difference "Geek.count", -1 do
      delete "/v1/geeks/#{@geek.id}"
    end
    assert_response :ok
    assert_equal 0, Apply.where(geek_id: @geek.id).count
    assert Job.exists?(@job.id)
  end

  test "missing records return JSON 404 on every member route" do
    [ [ :get, "/v1/companies/0" ], [ :put, "/v1/companies/0" ], [ :delete, "/v1/companies/0" ],
      [ :put, "/v1/companies/0/mark_deleted" ], [ :get, "/v1/companies/0/geeks" ],
      [ :get, "/v1/companies/0/applies" ], [ :get, "/v1/companies/0/jobs" ],
      [ :get, "/v1/jobs/0" ], [ :put, "/v1/jobs/0" ], [ :delete, "/v1/jobs/0" ],
      [ :get, "/v1/jobs/0/geeks" ], [ :get, "/v1/jobs/0/applies" ],
      [ :get, "/v1/geeks/0" ], [ :put, "/v1/geeks/0" ], [ :delete, "/v1/geeks/0" ],
      [ :get, "/v1/geeks/0/read_applies" ], [ :get, "/v1/geeks/0/invited_applies" ],
      [ :get, "/v1/geeks/0/applies" ], [ :put, "/v1/geeks/0/resume" ],
      [ :get, "/v1/applies/0" ], [ :put, "/v1/applies/0" ], [ :delete, "/v1/applies/0" ],
      [ :put, "/v1/applies/0/mark_read" ], [ :put, "/v1/applies/0/invite" ] ].each do |verb, path|
      public_send(verb, path)
      assert_response :not_found
      assert_equal "not_found", json.fetch("status")
    end
  end

  test "unknown routes and wrong HTTP verbs return JSON 404" do
    [ [ :get, "/" ], [ :get, "/jobs" ], [ :get, "/v1/unknown" ],
      [ :post, "/v1/jobs/#{@job.id}" ], [ :delete, "/v1/companies/#{@company.id}/mark_deleted" ] ].each do |verb, path|
      public_send(verb, path)
      assert_response :not_found
      assert_equal "no_route", json.fetch("status")
    end
  end

  test "malformed JSON and malformed resource wrappers return JSON 400" do
    post "/v1/companies", params: '{"name":', headers: { "CONTENT_TYPE" => "application/json" }
    assert_response :bad_request
    assert_equal "bad_request", json.fetch("status")
    [ nil, [], "invalid" ].each do |value|
      post "/v1/companies", params: { company: value }, as: :json
      assert_response :bad_request
    end
  end

  test "health endpoint responds successfully" do
    get "/up"
    assert_response :ok
  end

  private

  def json
    response.parsed_body
  end

  def ids(key)
    json.fetch(key.to_s).pluck("id")
  end
end
