require "URI"

module Atrium
  module Paginate
    DEFAULT_PAGE = 1
    DEFAULT_RECORDS_PER_PAGE = 25

    attr_accessor :current_page, :endpoint, :total_entries, :total_pages

    def endpoint_name(query_params: nil)
      @endpoint = if query_params.present?
         klass_name + "?" + URI.encode_www_form(query_params) + "&"
      else
        klass_name + "?"
      end
    end

    def klass_name
      @klass_name ||= self.name.gsub("Atrium::", "").downcase.pluralize
    end

    def paginate_endpoint(query_params: nil, limit: nil)
      endpoint_name(query_params: query_params)
      set_pagination_fields
      response_list(limit: limit)
    end

    def records_per_page
      @records_per_page ||= DEFAULT_RECORDS_PER_PAGE
    end

    def response_list(limit: nil)
      @total_pages = limit / records_per_page if limit.present? && total_pages > 1
      list = []

      until current_page > total_pages
        paginated_endpoint =  endpoint + "page=#{current_page}&records_per_page=#{records_per_page}"
        response = ::Atrium.client.make_request(:get, paginated_endpoint)

        # Add new objects to the list
        response["#{klass_name}"].each do |params|
          list << self.new(params)
        end
        @current_page += 1
      end
      list
    end

    def set_pagination_fields
      @current_page = DEFAULT_PAGE
      paginated_endpoint = endpoint + "page=#{current_page}&records_per_page=#{records_per_page}"
      response = ::Atrium.client.make_request(:get, paginated_endpoint)

      pagination = response["pagination"]
      @total_pages  = pagination["total_pages"]
    end
  end
end
