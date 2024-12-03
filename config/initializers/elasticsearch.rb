require 'elasticsearch/model'

Elasticsearch::Model.client = Elasticsearch::Client.new(
  host: ENV['ELASTICSEARCH_URL'],
  user: ENV['ELASTICSEARCH_USER'],
  password: ENV['ELASTICSEARCH_PASSWORD'],
  scheme: 'http',
  log: true
)
