class Book < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  index_name  ENV.fetch("ELASTICSEARCH_INDEX", "library")

  settings index: {
    analysis: {
      char_filter: {
        normalize: {
          type: 'icu_normalizer',
          name: 'nfkc',
          mode: 'compose'
        }
      },
      filter: {
        readingform: {
          type: 'kuromoji_readingform',
          use_romaji: true
        },
        cjk_width: {
          type: 'cjk_width'
        },
        english_possessive_stemmer: {
          type: 'stemmer',
          language: 'possessive_english'
        },
        english_stemmer: {
          type: 'stemmer',
          language: 'english'
        },
        romaji_readingform: {
          type: 'kuromoji_readingform',
          use_romaji: true
        },
        ngram_filter: {
          type: 'ngram',
          min_gram: 2,
          max_gram: 3
        }
      },
      tokenizer: {
        ja_kuromoji_tokenizer: {
          type: 'kuromoji_tokenizer',
          mode: 'search'
        }
      },
      analyzer: {
        ja_original_index_analyzer: {
          type: 'custom',
          char_filter: ['normalize'],
          tokenizer: 'ja_kuromoji_tokenizer',
          filter: [
            'cjk_width',
            'kuromoji_stemmer'
          ]
        },
        ja_readingform_index_analyzer: {
          type: 'custom',
          char_filter: ['normalize'],
          tokenizer: 'ja_kuromoji_tokenizer',
          filter: [
            'cjk_width',
            'readingform',
            'lowercase',
            'asciifolding'
          ]
        },
        ja_ngram_analyzer: {
          type: 'custom',
          tokenizer: 'standard',
          filter: [
            'cjk_width',
            'lowercase',
            'ngram_filter'
          ]
        },
        ja_readingform_search_analyzer: {
          type: 'custom',
          char_filter: ['normalize'],
          tokenizer: 'ja_kuromoji_tokenizer',
          filter: [
            'cjk_width',
            'readingform',
            'lowercase',
            'asciifolding'
          ]
        },
        romaji_analyzer: {
          tokenizer: 'kuromoji_tokenizer',
          filter: [
            'romaji_readingform',
            'lowercase',
            'asciifolding',
            'ngram_filter'
          ]
        },
        english_exact: {
          tokenizer: 'standard',
          filter: [
            'lowercase'
          ]
        },
        english_custom: {
          tokenizer: 'standard',
          filter: [
            'english_possessive_stemmer',
            'lowercase',
            'english_stemmer'
          ]
        }
      }
    }
  } do
    mappings dynamic: false do
      indexes :id, type: 'integer', index: false

      indexes :title_jp, type: 'text', analyzer: 'ja_original_index_analyzer', search_analyzer: 'ja_ngram_analyzer' do
        indexes :readingform, type: 'text', analyzer: 'ja_readingform_index_analyzer', search_analyzer: 'ja_readingform_search_analyzer'
      end

      indexes :author_jp, type: 'text', analyzer: 'english_custom', search_analyzer: 'english_custom'

      indexes :path_image, type: 'keyword', index: false
      indexes :path_download, type: 'keyword', index: false
      indexes :filesize, type: 'keyword', index: false
      indexes :filetype, type: 'keyword', index: false
    end
  end

  def self.search_books(query, author: nil, title: nil, exact_match: false, page: 1, per_page: 10)
    from = (page - 1) * per_page

    must_clauses = [
      {
        bool: {
          should: build_multi_language_query(query, exact_match: exact_match)
        }
      }
    ]

    filter_clauses = []

    if author.present?
      filter_clauses << {
        match: {
          author_jp: {
            query: author,
            operator: 'and',
            fuzziness: 1
          }
        }
      }
    end

    if title.present?
      filter_clauses << {
        bool: {
          should: build_multi_language_query(title, exact_match: exact_match)
        }
      }
    end

    es_query = {
      bool: {
        must: must_clauses,
        filter: filter_clauses
      }
    }

    response = __elasticsearch__.search(
      {
        query: es_query,
        from: from,
        size: per_page,
        highlight: {
          fields: {
            title_jp: {},
            'title_jp.readingform': {},
            title_romaji: {},
            author_jp: {}
          },
          pre_tags: ['<mark>'],
          post_tags: ['</mark>']
        }
      }
    )

    response.results.map do |result|
      {
        id: result._id,
        title: result._source.title_jp,
        highlighted_title: result.highlight&.title_jp&.first || result._source.title_jp,
        highlighted_title_readingform: result.highlight&.dig('title_jp.readingform')&.first || nil,
        author: result._source.author_jp,
        highlighted_author: result.highlight&.author_jp&.first || result._source.author_jp,
        path_image: result._source.path_image,
        path_download: result._source.path_download,
        score: result._score,
        filesize: result._source.filesize,
        filetype: result._source.filetype,
        source: result._source.source
      }
    end
  end

  def self.build_multi_language_query(query, exact_match: false)
    should_clauses = []

    fuzziness = exact_match ? nil : "AUTO"

    should_clauses << {
      multi_match: {
        query: query,
        fields: exact_match ? ['title_jp'] : ['title_jp^5', 'title_jp.readingform^3', 'title_romaji^2'],
        type: 'best_fields',
        operator: 'and',
        fuzziness: fuzziness,
        minimum_should_match: '80%'
      }.compact
    }

    should_clauses << {
      match: {
        author_jp: {
          query: query,
          operator: 'and',
          fuzziness: 0
        }
      }
    }

    should_clauses
  end

end
