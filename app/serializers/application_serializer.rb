# Explicit JSON fields using Rails' built-in serialization, without an extra gem.
class ApplicationSerializer
  def self.serialize(record)
    record.serializable_hash(only: self::ATTRIBUTES)
  end
end
