# Copyright (C) 2010 Cykod LLC.


class BookPage < DomainModel

  belongs_to :book_book

  acts_as_nested_set :scope => :book_book_id

  validates_presence_of :name

  validates_presence_of :book_book

  has_many :book_page_versions

  apply_content_filter(:body => :body_html)  do |page|
    { :filter => page.book_book.content_filter,
      :folder_id => page.book_book.image_folder_id, 
      :pre_filter => Proc.new { |code| page.replace_page_links(code)}
    }
  end

  attr_accessor :edit_type, :editor, :remote_ip, :v_status, :created_by_id, :prev_version

  before_save :create_url
  after_move :path_update
  after_save :force_resave_children
  after_save :auto_save_version
 # after_update :auto_save_version

  content_node :container_type => 'BookBook', :container_field => 'book_book_id',
  :except => Proc.new { |pg| !pg.parent_id }, :published => :published

  def export_csv(writer,options = {}) #:nodoc:
    fields = [ ['id', 'Page ID'.t ],
               ['name', 'Page Title'.t ],
               ['description', 'Description'.t ],
               ['published', 'Published'.t ],
               ['body', 'Page Body'.t ],
               ['parent_id', 'Parent Title'.t ]
             ] 
    opts = options.delete(:include) ||  []
   
    
    
     
    
    if options[:header]
      writer << fields.collect do |fld|
        fld[1]
      end
    end
    writer << fields.collect do |fld|
      if fld[0]
        self.send(fld[0])
      else
        fld[2]
      end
    end
  end

 
 
  def full_title
    self.book_book.name.to_s + ": " + self.name.to_s
  end

  def content_description(language)
    "Page in \"%s\" Book" / self.book_book.name
  end

  def content_node_body(language)
    self.body_html
  end

  def child_cache
    @child_cache ||= []
  end

  def child_cache=(val)
    @child_cache ||= []
    @child_cache << val
  end

  def parent_page
     ((self.parent && self.parent.parent_id) ? self.parent : nil)
  end

  def next_page
    @next_page ||= self.children[0] || BookPage.find(:first,:conditions => ['parent_id = ? AND book_book_id=? AND  lft > ?',self.parent_id,self.book_book_id,self.lft ], :order => 'lft') || :none
    @next_page == :none ? nil : @next_page
  end
  
  def forward_page
    @forward_page ||= BookPage.find(:first,:conditions => ['book_book_id=? AND lft > ?',self.book_book_id,self.lft ], :order => 'lft') || :none

    @forward_page == :none ? nil : @forward_page
  end

  def previous_page
    @previous_page ||= BookPage.find(:first,:conditions => ['parent_id = ? AND lft < ?',self.parent_id,self.lft ],:order => 'lft DESC') || :none
    @previous_page == :none ? nil : @previous_page
  end

  # Go to previous page or up
  def back_page
    @back_page ||=  BookPage.find(:first,:conditions => ['book_book_id=? AND lft < ?',self.book_book_id,self.lft ],:order => 'lft DESC')
    if @back_page != :none
      @back_page = :none if  !@back_page ||  !@back_page.parent_id
    end
    @back_page == :none ? nil : @back_page
  end
  

  def replace_page_links(code)
    cd = code.gsub(/\[\[([^\]]+)\]\](\(([^\)]+)\))?/) do |mtch|
      titleinbrackets = $1 
      linkinparens = $2
      linktext = $3
      if linktext
        newlink = $3.gsub(/[ _]+/,"-").downcase
      "[#{titleinbrackets}](#{newlink})"
      else
        newlink = $1.gsub(/[ _]+/,"-").downcase
        "[#{titleinbrackets}](#{newlink})"
      end
    end
    cd
  end

  def save_version(editor,version_body,v_type,v_status,ipaddress,orig_rev)
    self.book_page_versions.create(
                                   :name => self.name,
                                   :book_book_id => self.book_book_id,
                                   :body => version_body,
                                   :body_diff => page_diff(version_body,orig_rev),
                                   :created_by_id => editor,
                                   :version_status => v_status, 
                                   :version_type => v_type,
                                   :ipaddress => ipaddress)
  end
  
  def auto_save_version
    if v_status == nil
      orig_revision = book_page_versions.latest_revision || nil
    end
    save_version(editor||self.created_by_id,self.body,edit_type||'admin editor',v_status||'auto',remote_ip,prev_version)
  end
  protected
  
 
  def page_diff(version_body,orig_rev)
    version_body = version_body.to_s
    tmstmp = Time.now.strftime("%Y%m%d%H%M%S")
    tmp_loc = File.join(Rails.root, "tmp/export")
    max_lines = 9999999 
    diff_header_length = 3
    
    if !orig_rev.blank?
      page = book_page_versions.find_by_id(orig_rev)
      if page.body.nil?
        page_body_old = ""
      else
        page_body_old = page.body.gsub(/(\n| )/,"\\1\n") 
      end
    end

    if version_body.blank?
      page_body_new = ""
    else
      page_body_new = version_body.gsub(/\r\n/,"\n").gsub(/(\n| )/,"\\1\n")
    end


    tmp_orig_body = File.join(tmp_loc,"page_body_old-#{tmstmp}".to_s)
    tmp_vers_body = File.join(tmp_loc,"page_body_new-#{tmstmp}".to_s)

    file_orig      = File.new(tmp_orig_body, "w+") 
    file_vers      = File.new(tmp_vers_body, "w+")

    file_orig.write("#{page_body_old}\n") 
    file_vers.write("#{page_body_new}\n")


    file_orig.close
    file_vers.close
    lines = %x(diff --unified=#{max_lines} #{tmp_orig_body} #{tmp_vers_body})

     if lines.empty?
       lines = page_body_new.split(/\n/)
     else
       
       lines = lines.split(/\n/)[diff_header_length..max_lines].
         collect do |i|
        if i == "  "
          i = " "
        else
          case i[0,1]
          when "+": [1, i[1..i.length-1]+"\n"]
          when "-": [-1, i[1..i.length-1]+"\n"]
          else;  i[1..i.length-1]+"\n"
          end
        end
       end
     end

  
    
    lines.inject([]) do |output,elem| 
      if output[-1].class != elem.class
        output << elem 
      else
        if elem.is_a?(String) 
          output[-1] << elem
     
          
          output
        elsif output[-1][0] == elem[0]
          output[-1][1] << elem[1]
          output
        else
          output << elem

        end
        
      end
    end
    File.delete(tmp_orig_body)
    File.delete(tmp_vers_body)
  end
  def create_url
    logger.warn('Create URL')
    if  self.book_book.id_url?
      self.url = self.id.to_s
    else
      name_base = self.name.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
         logger.warn(self.url)
         logger.warn(name_base)

      if name_base != self.url

        cnt = 1
        name_try = name_base

        while check_duplicate(name_try)
          name_try = name_base + '-' + cnt.to_s

          cnt += 1
        end

        self.url = name_try

      end

    end

    if self.parent_id || self.book_book.book_type == 'flat'
      path_update(true)
    end
    
  end

  def path_update(skip_save=false)
    logger.warn('Path Update')
    if self.book_book.flat_url? || self.book_book.id_url?
      self.path = "/" + self.url.to_s
         logger.warn(self.path)

    else
      self.path = self.parent.path.to_s + "/" + self.url.to_s
    end
    
    if self.path_changed? && !self.book_book.flat_url?
      @force_resave_children = true
      self.save unless skip_save
    end
    
  end

  def force_resave_children
    logger.warn('Force Resave Children')
    if @force_resave_children
      self.children.each do |child|
        child.save
      end
    end
  end

 

  def check_duplicate(name)
    if self.book_book.flat_url?
      if self.id == nil
      self.book_book.book_pages.find(:first,:conditions => ['`url`=? ',name])
      else
        self.book_book.book_pages.find(:first,:conditions => ['`url`=? AND book_pages.id != ? ',name,self.id])
      end
    else
      self.book_book.book_pages.find(:first,:conditions => ['`url`=? AND book_pages.id != ? AND parent_id=? ',name,self.id,self.parent_id])
    end
  end
end
