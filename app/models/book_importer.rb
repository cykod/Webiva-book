require 'nokogiri'

class BookImporter < HashModel
  attributes :xml => nil, :book => nil, :images => nil, :rss_file_id => nil, :url => nil, :csv_file_id => nil
  
  domain_file_options :rss_file_id, :csv_file_id
  
  attr_accessor :host, :base_url
  
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def validate
    if self.rss_file
      self.import_file
      self.errors.add(:file_id, 'is not an RSS Feed') unless self.xml && self.xml.include?('<channel>')
    elsif ! self.url.blank?
      self.import_site
      self.errors.add(:url, 'is not a valid RSS Feed') unless self.xml && self.xml.include?('<channel>')
    elsif self.csv_file
      self.errors.add(:csv_file_id, 'is not valid') unless self.csv_file.mime_type == 'text/csv'
    else
      self.errors.add(:csv_file_id, 'is missing')
      self.errors.add(:rss_file_id, 'is missing')
      self.errors.add(:url, 'is missing')
    end
  end

  def folder
    self.book.image_folder
  end

  def import_site
    begin
      self.xml = DomainFile.download(self.url).body.to_s
    rescue
      false
    end
  end

  def import_file
    File.open(self.rss_file.filename, 'r') { |f| self.xml = f.read }
  end

  def rss_header
    @rss_header ||= '<?xml version="1.0" encoding="UTF-8"?>' + self.xml.match(/(<rss.*?>)/m).to_s
  end

  def rss_footer
    '</rss>'
  end

  def book_pages
    self.xml.scan /<item>.*?<\/item>/m do |item|
      item = item.to_s
      item = Hash.from_xml "#{self.rss_header}#{item}#{self.rss_footer}"
      item = item['rss'] && item['rss']['item'] ? item['rss']['item'] : nil
      yield item if item
    end
  end

  def import
    unless self.xml.include?('<channel>')
      self.error = 'RSS file is invalid'
      return false
    end

    self.base_url = $1 if self.xml =~ /<link>(.*?)<\/link>/
    begin
      self.host = URI.parse(self.base_url).host if self.base_url
    rescue
    end

    Rails.logger.error "base_url(#{self.base_url}) host(#{self.host})"
    
    self.book_pages do |item|
      self.create_page item
    end

    true
  end

  def parse_body(body)
    body.gsub!(/src=("|')([^\1]+?)\1/) do |match|
      quote = $1
      src = $2
      file = nil
      if self.base_url && self.host
        src = "http://#{self.host}#{src}" if src =~ /^\//
        src = "http://#{self.base_url}/#{src}" unless src.include?('http')
      end
        
      file = self.folder.add(src) if src =~ /^http/ && src.length < 200
      if file
        self.images[src] = file
        "src=#{quote}images/#{file.name}#{quote}"
      else
        match
      end
    end

    self.images.each do |src, file|
      body.gsub! src, file.editor_url
    end

    body.strip!
    body
  end

  def create_page(item)
    body = item['description']
    return if body.blank?

    page = self.book.book_pages.create :name => item['title'], :body => self.parse_body(body), :published => true
    page.move_to_child_of(self.book.root_node) unless self.book.flat_book?
    page
  end
  
end
