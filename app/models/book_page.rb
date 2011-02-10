# Copyright (C) 2010 Cykod LLC.

class BookPage < DomainModel
  belongs_to :book_book
  belongs_to :updated_by, :class_name => 'EndUser', :foreign_key => :updated_by_id
  belongs_to :created_by, :class_name => 'EndUser', :foreign_key => :created_by_id

  acts_as_nested_set :scope => :book_book_id

  validates_presence_of :name

  validates_presence_of :book_book

  has_many :book_page_versions, :dependent => :delete_all

  apply_content_filter(:body => :body_html)  do |page|
    { :filter => page.book_book.content_filter,
      :folder_id => page.book_book.image_folder_id, 
      :pre_filter => Proc.new { |code| page.replace_page_links(code) }
    }
  end

  attr_accessor :edit_type, :editor, :remote_ip, :v_status, :prev_version

  after_create :create_id_url
  before_save :create_url
  after_move :path_update
  after_save :force_resave_children
  after_save :auto_save_version

  content_node :container_type => 'BookBook', :container_field => 'book_book_id',
    :except => Proc.new { |pg| !pg.parent_id }, :published => :published

  cached_content :update => [ :book_book ]

  def full_title
    "#{self.book_book.name}: #{self.name}"
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
    @next_page ||= self.children[0] || BookPage.first(:conditions => ['parent_id = ? AND book_book_id=? AND lft > ?',self.parent_id,self.book_book_id,self.lft ], :order => 'lft') || :none
    @next_page == :none ? nil : @next_page
  end
  
  def previous_page
    @previous_page ||= BookPage.first(:conditions => ['parent_id = ? AND lft < ?', self.parent_id, self.lft], :order => 'lft DESC') || :none
    @previous_page == :none ? nil : @previous_page
  end

  def forward_page
    @forward_page ||= BookPage.first(:conditions => ['book_book_id = ? AND lft > ?', self.book_book_id, self.lft], :order => 'lft') || :none
    @forward_page == :none ? nil : @forward_page
  end

  # Go to previous page or up
  def back_page
    @back_page ||=  BookPage.first(:conditions => ['book_book_id = ? AND lft < ? AND parent_id IS NOT NULL', self.book_book_id, self.lft], :order => 'lft DESC') || :none
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

  def save_version(editor,version_body,v_type,v_status,ipaddress,orig_rev=nil)
    self.book_page_versions.create(:name => self.name,
                                   :book_book_id => self.book_book_id,
                                   :base_version_id => orig_rev,
                                   :body => version_body,
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

  def page_diff(version_body)
    curr_ver_body = version_body

    max_lines = 99999999 
    diff_header_length = 3
    page_body_old = (self.body || '').gsub(/\r\n/,"\n").gsub(/(\n| )/,"\\1\n")

    if version_body.blank?
      page_body_new = ""
    else
      page_body_new = version_body.gsub(/\r\n/,"\n").gsub(/(\n| )/,"\\1\n")
    end
    
    return [page_body_new] if page_body_new == page_body_old
    
    tmp_orig_body = "page_body_old"
    tmp_vers_body = "page_body_new"

    file_orig      = Tempfile.new(tmp_orig_body) 
    file_vers      = Tempfile.new(tmp_vers_body)

    file_orig.write("#{page_body_old}\n") 
    file_vers.write("#{page_body_new}\n")

    file_orig.close
    file_vers.close

    lines = %x(diff --unified=#{max_lines} #{file_orig.path} #{file_vers.path})
    
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

    file_orig.unlink
    file_vers.unlink 
    
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
  end

  @@export_fields = [
    [:url, 'Page URL'],
    [:name, 'Page Title'],
    [:description, 'Description'],
    [:published, 'Published'],
    [:body, 'Page Body'],
    [:parent_url, 'Parent URL']
  ]
  def self.export_fields; @@export_fields; end

  def export_csv_header(writer, options={}) #:nodoc:
    writer << self.class.export_fields.collect { |fld| fld[1].t }
  end

  def export_csv(writer, options={}) #:nodoc:
    self.export_csv_header(writer, options) if options[:header]
    writer << self.class.export_fields.collect { |fld| self.send(fld[0]) }
  end

  def self.import_csv(book, user, row, options={}) #:nodoc:
    attr = {}
    self.export_fields.each_with_index { |field,idx| attr[field[0]] = row[idx] }

    page = nil
    page_parent = nil
    unless attr[:url].blank?
      if attr[:parent_url].blank?
        page = book.book_pages.find_by_url(attr[:url])
      else
        book.book_pages.find(:all, :conditions => {:url => attr[:parent_url]}).each do |page_parent|
          page = book.book_pages.find_by_url_and_parent_id(attr[:url], page_parent.id)
          break if page
        end
      end
    end

    return (page || attr) if options[:no_save]

    if page
      page.update_attributes(attr.slice(:name,:description,:published,:body))
    else
      page = book.book_pages.new(attr.slice(:name,:description,:published,:body))
      page.created_by_id = user.id if user
      page.save
    end

    page.move_to_child_of(page_parent || book.root_node) unless book.flat_book?
    page
  end

  protected

  def create_id_url
    return unless self.book_book.id_url?
    self.update_attributes :url => self.id.to_s, :path => "/#{self.id}"
  end

  def create_url
    return if self.book_book.id_url?

    return if self.name.downcase == 'new page'

    name_base = self.url.blank? ? SiteNode.generate_node_path(self.name) : self.url

    if name_base != self.url || self.id.nil? || self.url_changed?
      cnt = 1
      name_try = name_base

      while check_duplicate(name_try)
        name_try = name_base + '-' + cnt.to_s
        cnt += 1
      end

      self.url = name_try
    end

    self.path_update(true)
  end

  def path_update(skip_save=false)
    if self.book_book.nested_url? && self.parent && self.parent != self.book_book.root_node
      self.path = "#{self.parent.path}/#{self.url}"
    else
      self.path = "/#{self.url}"
    end

    if self.path_changed? && self.book_book.nested_url?
      @force_resave_children = true
      self.save unless skip_save
    end
  end

  def force_resave_children
    if @force_resave_children
      self.children.each do |child|
        child.save
      end
      @force_resave_children = false
    end
  end

  def check_duplicate(name)
    scope = self.book_book.book_pages.scoped(:conditions => {:url => name})
    scope = scope.scoped(:conditions => ['book_pages.id != ?', self.id]) if self.id
    scope = scope.scoped(:conditions => {:parent_id => self.parent_id}) if self.book_book.nested_url? && self.parent_id
    scope.first
  end
end
