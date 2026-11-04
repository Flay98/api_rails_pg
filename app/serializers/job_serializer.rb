class JobSerializer < ApplicationSerializer
  ATTRIBUTES = %i[id name place company_id deleted].freeze
end
