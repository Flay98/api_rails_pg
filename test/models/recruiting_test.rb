require "test_helper"

class RecruitingTest < ActiveSupport::TestCase
  setup do
    @company = Company.create!(name: "MoGo", location: "New York")
    @job = @company.jobs.create!(name: "Sinatra React", place: "Remote")
    @geek = Geek.create!(name: "Mike", stack: "Sinatra React")
    @apply = Apply.create!(job: @job, geek: @geek)
  end

  test "required text fields and their lengths are validated" do
    { Company => %i[name location], Job => %i[name place], Geek => %i[name stack] }.each do |model, fields|
      record = { Company => @company, Job => @job, Geek => @geek }.fetch(model)
      fields.each do |field|
        original = record[field]
        [ nil, "", " ", "x" * 256 ].each do |value|
          record[field] = value
          assert_not record.valid?, "#{model}.#{field} accepted #{value.inspect}"
          assert record.errors[field].present?
        end
        record[field] = original
      end
    end
  end

  test "resume is optional text" do
    assert_nil @geek.resume
    @geek.update!(resume: "Ruby developer\nRails and PostgreSQL")
    assert_includes @geek.reload.resume, "PostgreSQL"
  end

  test "foreign ids must be positive integers and refer to existing records" do
    [ [ @job, :company_id ], [ @apply, :job_id ], [ @apply, :geek_id ] ].each do |record, field|
      original = record[field]
      [ nil, -1, 0, "abc", "1.5", 2_000_000_000 ].each do |value|
        record[field] = value
        assert_not record.valid?, "#{field} accepted #{value.inspect}"
      end
      record[field] = original
      assert record.valid?
    end
  end

  test "associated models must also be valid" do
    @company.name = nil
    assert_not @job.valid?
    assert @job.errors[:company].present?
    @company.name = "MoGo"
    @geek.stack = nil
    assert_not @apply.valid?
    assert @apply.errors[:geek].present?
  end

  test "false is a valid status and is the default" do
    assert_equal false, @apply.read
    assert_equal false, @apply.invited
    assert @apply.valid?
    assert_equal false, @company.deleted
    assert_equal false, @job.deleted
  end

  test "invalid boolean values are rejected instead of silently becoming true" do
    %i[read invited].each do |field|
      [ nil, "", "yes", "banana", 3 ].each do |value|
        @apply[field] = value
        assert_not @apply.valid?
        assert @apply.errors[field].present?
      end
      @apply[field] = false
    end
  end

  test "associations return related records and distinct applicants" do
    second_job = @company.jobs.create!(name: "Rails", place: "London")
    Apply.create!(job: second_job, geek: @geek)
    assert_equal [ @geek ], @company.geeks.to_a
    assert_equal [ @geek ], @job.geeks.to_a
    assert_equal 2, @geek.jobs.count
    assert_equal [ @company ], @geek.companies.to_a
    assert_equal 2, @company.applies.count
  end

  test "soft deletes preserve companies jobs and applications" do
    assert_no_difference [ "Company.count", "Job.count", "Apply.count" ] do
      assert @company.delete_company
      assert @job.delete_job
      assert @company.delete_company
    end
    assert @company.reload.deleted?
    assert @job.reload.deleted?
    assert Apply.exists?(@apply.id)
  end

  test "deleting a geek removes its applications without removing jobs" do
    assert_difference "Apply.count", -1 do
      @geek.destroy!
    end
    assert Job.exists?(@job.id)
  end

  test "database enforces foreign keys and non null fields" do
    assert_raises ActiveRecord::InvalidForeignKey do
      Apply.transaction(requires_new: true) { @apply.update_columns(job_id: 2_000_000_000) }
    end
    assert_raises ActiveRecord::NotNullViolation do
      Company.transaction(requires_new: true) { @company.update_columns(name: nil) }
    end
    assert_raises ActiveRecord::NotNullViolation do
      Apply.transaction(requires_new: true) { @apply.update_columns(read: nil) }
    end
  end

  test "seeds are repeatable and preserve existing custom records" do
    custom = Company.create!(name: "Custom company", location: "Tomsk")
    counts = nil
    2.times do
      load Rails.root.join("db/seeds.rb")
      current = [ Company.count, Job.count, Geek.count, Apply.count ]
      assert_equal counts, current if counts
      counts = current
    end
    assert_equal [ 5, 7, 9, 4 ], counts
    assert Company.exists?(custom.id)
    assert Company.exists?(@company.id)
    assert Apply.exists?(@apply.id)
    assert_equal 3, Company.find_by!(name: "BuildEmpire").jobs.count
  end
end
