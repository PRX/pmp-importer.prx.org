require 'digest/md5'

class Object
  def as_digest
    to_s
  end

  def to_digest
    Digest::SHA256.base64digest(as_digest)
  end
end

class Array
  def as_digest
    map(&:as_digest).join
  end
end

class Hash
  def as_digest
    sort.map(&:as_digest).join
  end
end
