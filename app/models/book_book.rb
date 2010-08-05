# Copyright (C) 2010 Cykod LLC.


class BookBook < DomainModel

  has_domain_file :cover_file_id
  has_domain_file :thumb_file_id

  has_many :book_page_versions, :dependent => :destroy, :order => 'book_page_versions.name'
  has_many :book_pages, :dependent => :destroy, :order => 'book_pages.name'

  after_create :create_root_node

  attr_accessor :add_to_site

  has_options :book_type, [ [ 'Chapter Based', 'chapter'],
                            [ 'Flat','flat' ]
                          ]

  belongs_to :style_template, :class_name => 'SiteTemplate', :foreign_key => 'style_template_id'
  
  has_options :url_scheme, [ ['Flat','flat'],['Nested','nested'],['ID','id']]

  validates_presence_of :name
  validates_format_of :preview_wrapper, :allow_blank => true, :with => /^(\.|\#)/

  attr_protected :url_scheme, :book_type

  content_node_type :book, "BookPage", :content_name => :name,:title_field => :full_title, :url_field => :url

  
  def content_admin_url(book_page_id)
    {  :controller => '/book/manage', :action => 'edit', :path => [ self.id, book_page_id ],
       :title => 'Edit Book Page'.t}
  end

  def content_type_name
    "Book"
  end

  def root_node
    @root_node ||= self.book_pages.find(:first,:conditions => 'parent_id IS NULL', :order => 'book_pages.id')

  end
  def flat_book?
    self.book_type == 'flat'
  end

  def flat_url?
    self.url_scheme == 'flat'
  end

  def id_url?
    self.url_scheme == 'id'
  end

  def nested_url?
    self.url_scheme == 'nested'
  end  

  def create_root_node
    self.book_pages.create(:name => 'Root', :created_by_id => self.created_by_id) unless book_type == 'flat'
  end

  def flat_pages
    page_hash = {self.root_node.id => self.root_node }

  end

  # get a nested structure with 1 DB call
  def nested_pages

    if book_type == 'flat'

      self.book_pages
    else
      page_hash = {self.root_node.id => self.root_node }

      self.root_node.descendants.each do |nd|
        page_hash[nd.parent_id].child_cache << nd
        page_hash[nd.id] = nd
      end

      
      page_hash[root_node.id].child_cache
    end
  end
  
  def  first_page
    if book_type == 'flat'
      self.book_pages.find(:first)
    else
      self.root_node.children[0]
    end
    
  end
  
  def preview_wrapper_start
    case preview_wrapper[0..0]
    when '.'
      "<div class='#{preview_wrapper[1..-1]}'>"
    when '#'
      "<div id='#{preview_wrapper[1..-1]}'>"
    else
      "<div>"
    end
  end

  def preview_wrapper_end; '</div>'; end

  def export_book(args) 
    results = { }
    # args = { :book_id, :export_download, :export_format, :range_start, :range_end }
    
    results[:completed] = false
        
    
    @pages = self.book_pages.find(:all, :conditions => ["name != ?",'Root'])

    tmp_path = "#{RAILS_ROOT}/tmp/export/"
    FileUtils.mkpath(tmp_path)
    
    dom_id =  Domain.find(DomainModel.active_domain_id).id.to_s
    filename  = tmp_path + "domain:" + dom_id + "-book:" + self.id.to_s + "_book_export"
    results[:filename] = filename

     
    CSV.open(filename,'w') do |writer|
      @pages.each_with_index do |page,idx|
        page.export_csv(writer,  :header => idx == 0,
                                 :include => args[:export_options])
      end
    end
    results[:entries] = @pages.length
    results[:type] = 'csv'
    results[:completed] = 1
    
    results
  end

  def do_import(args,user) #:nodoc:
   results = { }
   
   
   results[:completed] = false

   count = -1
   CSV.open(args,"r",",").each do |row|
     count += 1 if !row.join.blank?
   end
   count = 1 if count < 1
   results[:entries] = count
   
   results[:initialized] = true
   results[:imported] = 0
   
   
   
   
   self.parse_csv(args,user) do |imported,errors|
     results[:imported] += imported
     Workling.return.set(args[:uid],results)
   end
 
 results[:completed] = true
 Workling.return.set(self.id,results)
 
  end

  def check_header(f)     
    reader = CSV.open(f, "r")
    @header = reader.shift
    @@fields = ["id","name","description","published","body","parent_id"]
    if @header == @@fields
      return true
    else
      return false
    end
  end

 def parse_csv(args,user) 
   @@fields = [:id,:name,:description,:published,:body,:parent_id]
   reader = CSV.open(args,"r",",")
   reader.shift
   reader.each do |row|
     attr = {}
     @@fields.each_with_index { |field,idx| attr[field] = row[idx] }
     
     
     @page = self.book_pages.find_by_id(attr[:id]) 
     @page_parent = self.book_pages.find_by_id(attr[:parent_id])
     if @page_parent 
       @page_name = self.book_pages.find_by_name_and_parent_id(attr[:name],@page_parent.id)
     else
       @page_name = self.book_pages.find_by_name(attr[:name])
     end

     if @page
       @page.update_attributes(attr.slice(:name,
                                          :description,
                                          :published,
                                          :body
                                          ))
       @page.move_to_child_of(@page_parent || self.root_node) unless flat_book?
       
     elsif @page_name
       @page_name.update_attributes(attr.slice(
                                               :description,
                                               :published,
                                               :body
                                               ))
       @page_name.move_to_child_of(@page_parent || self.root_node) unless flat_book?
       
     else
       @page = self.book_pages.new(attr.slice(:name,
                                              :description,
                                              :published,
                                              :body
                                              ))
       @page.editor = user
       @page.save
       @page.move_to_child_of(@page_parent || self.root_node) unless flat_book?
       
       
     end
     
   end
 end
 
end
