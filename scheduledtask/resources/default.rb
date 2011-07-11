actions :create, :delete, :enable, :disable

attribute :name,    :kind_of => String, :name_attribute => true
attribute :command, :kind_of => String
attribute :start,   :kind_of => String
attribute :repeat,  :kind_of => String, :equal_to => [ "Daily", "xMinutes" ]
attribute :minutes, :kind_of => String, :default => ""

def initialize(*args)
  super
  @action = :create
end