# Repeatable and non-destructive: no deletes, fixed IDs, or sequence resets.
# resume is text in the schema; the manual's true/false examples become text/nil.
ActiveRecord::Base.transaction do
  companies = [
    [ "MoGo", "New York" ],
    [ "Wirkkle", "London" ],
    [ "Artesis", "Saint-Petersburg" ],
    [ "BuildEmpire", "London" ]
  ].map do |name, location|
    Company.find_or_create_by!(name: name, location: location)
  end

  jobs = [
    [ "Sinatra React", "Remote", 0 ],
    [ "Ruby React", "Contract", 1 ],
    [ "React", "Remote", 2 ],
    [ "Node React", "Permanent", 0 ],
    [ "Ruby on Rails", "Remote", 3 ],
    [ "Node", "Permanent", 3 ],
    [ "Javascript CSS HTML", "Permanent", 3 ]
  ].map do |name, place, company_index|
    companies[company_index].jobs.find_or_create_by!(name: name, place: place)
  end

  geeks = [
    [ "Mike", "Sinatra React", true ],
    [ "Alex", "Ruby React", true ],
    [ "Martha", "Rails", false ],
    [ "Juri", "Java", true ],
    [ "Andrew", "PHP", false ],
    [ "Nina", "Node", true ],
    [ "Bob", "Front end", true ],
    [ "Kate", "PHP", false ],
    [ "Boris", "Full stack", true ]
  ].map do |name, stack, has_resume|
    Geek.find_or_create_by!(name: name, stack: stack) do |geek|
      geek.resume = has_resume ? "#{name}: #{stack}" : nil
    end
  end

  [
    [ 0, 0, true, true ],
    [ 0, 1, false, false ],
    [ 4, 4, true, false ],
    [ 5, 7, false, false ]
  ].each do |job_index, geek_index, read, invited|
    Apply.find_or_create_by!(job: jobs[job_index], geek: geeks[geek_index]) do |apply|
      apply.read = read
      apply.invited = invited
    end
  end
end
