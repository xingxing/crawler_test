# coding: utf-8
require 'json/ext'

# 任务： 封装公司数据
# IT橘子URL、公司页URL、产品名称、公司名称、地点、阶段、公司招聘页面的url
class Company
  
  attr_accessor :data
  
  def initialize(options={})
    @data = options.select do |k, _|
      [:itjuzi_url,
       :company_home_url,
       :company_name,
       :product_name,
       :company_location,
       :stage,
       :hire_url].include?(k)
    end
  end

  def to_json
    data.to_json
  end

end
