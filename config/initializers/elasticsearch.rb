require 'elasticsearch/model'


Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: ENV['ELASTICSEARCH_HOST'],
  user: ENV['ELASTICSEARCH_USER'],
  password: ENV['ELASTICSEARCH_PASSWORD']
)
