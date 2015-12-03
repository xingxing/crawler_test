# coding: utf-8
require "faraday"
require "nokogiri"
require_relative "company.rb"


module Crawl

  IT_JUZI_COMPANY_BASE_URL = "http://itjuzi.com/company"

  class << self

    # 嗅探n个公司
    def sniffing n=1

      company_id = 1
      company_infos = [] #=> [company1, company2 ... ]
      file = File.new("companys", "a+")

      add = Proc.new do 
        begin
          url = company_url(company_id)

          response = request url

          if response.status == 200
            body = response.body
            doc = Nokogiri::HTML(body)
            info_detail_on_itzuji = parse_info_detail doc
            p info_detail_on_itzuji
            company_home_url      = info_detail_on_itzuji[:company_home_url]
            company_info = Company.new( info_detail_on_itzuji.merge( parse_hire_url( company_home_url  ).merge( {itjuzi_url: url} ) ) )
            company_infos <<  company_info
          end

          file.puts company_info.to_json
          
          company_id += 1
        # rescue Exception => e
        #   puts "Exception: --- "+e.message
        #   company_id += 1
        end
      end

      until company_infos.size == 1
        add.call
      end
      
      p company_infos.map{|c| c.to_json}
      
    end

    def request url

      conn = Faraday.new(:url => url) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      
      conn.get do |req|
        req.options.timeout = 5000           # open/read timeout in seconds
        req.options.open_timeout = 2000      # connection open timeout in seconds
      end
      
      # Faraday.get url
    end

    def parse_info_detail doc
      { company_home_url: doc.search("ul.detail-info li a")[0].text.strip,
        company_name:     doc.search("ul.detail-info li em")[0].text.strip,
        company_location: doc.search("ul.detail-info li em")[2].text.strip,
        product_name:     doc.search("#com_id_value").text.strip,
        stage:            doc.search("ul.detail-info li a")[3].text.strip }
    end

    def parse_hire_url company_home_url 
      response = request company_home_url
      if response.status == 200
        body = response.body
        doc  = Nokogiri::HTML(body)        
        { hire_url: doc.search("a:contains('招聘')","a:contains('join')", "a:contains('加入')" ).map{|e| p e.attributes["href"].value }.uniq }
      else
        { hire_url: [] }
      end
    end

    def company_url company_id
      File.join( IT_JUZI_COMPANY_BASE_URL, company_id.to_s )
    end


  end

end

Crawl.sniffing
