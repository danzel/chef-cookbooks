#Resource

actions :create, :delete

attribute :name,        :kind_of => String, :name_attribute => true
attribute :path,        :kind_of => String
attribute :dotnet,      :kind_of => String, :default => "4.0", :equal_to => [ "2.0", "4.0" ]
attribute :bindings,    :kind_of => Array, :default => []
attribute :sslbindings, :kind_of => Array, :default => []


def initialize(*args)
  super
  @action = :create
end