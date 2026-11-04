class CompanySerializer < ApplicationSerializer
  ATTRIBUTES = %i[id name location deleted].freeze
end
