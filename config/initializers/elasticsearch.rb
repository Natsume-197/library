require 'elasticsearch/model'

Elasticsearch::Model.client = Elasticsearch::Client.new(
  url: ENV.fetch('ELASTICSEARCH_URL', 'http://localhost:9200'),
  user: ENV.fetch('ELASTICSEARCH_USER', ''),
  password: ENV.fetch('ELASTICSEARCH_PASSWORD', ''),
  scheme: 'http',
  log: true
)
