actions :set

attribute :name,      :kind_of => String, :name_attribute => true
attribute :ip,        :kind_of => String
attribute :port,      :kind_of => Integer
attribute :certregex, :kind_of => String

def initialize(*args)
  super
  @action = :set
end
