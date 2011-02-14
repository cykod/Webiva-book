# Copyright (C) 2010 Cykod LLC.

require 'csv'

class BookBook < DomainModel
  has_domain_file :cover_file_id
  has_domain_file :thumb_file_id
  belongs_to :created_by, :class_name => 'EndUser', :foreign_key => :created_by_id
  belongs_to :image_folder, :class_name => 'DomainFile', :foreign_key => :image_folder_id
  
  has_many :book_page_versions, :order => 'book_page_versions.name'
  has_many :book_pages, :dependent => :destroy, :order => 'book_pages.name'

  attr_accessor :add_to_site

  has_options :book_type, [['Chapter Based', 'chapter'], ['Flat','flat']]

  belongs_to :style_template, :class_name => 'SiteTemplate', :foreign_key => 'style_template_id'
  
  has_options :url_scheme, [['Flat','flat'], ['Nested','nested'], ['ID','id']]

  validates_presence_of :name
  validates_format_of :preview_wrapper, :allow_blank => true, :with => /^(\.|\#)/

  attr_protected :url_scheme, :book_type

  content_node_type :book, "BookPage", :content_name => :name, :title_field => :full_title, :url_field => :url

  cached_content

  def content_admin_url(book_page_id)
    {:controller => '/book/manage', :action => 'edit', :path => [self.id, book_page_id], :title => 'Edit Book Page'.t}
  end

  def content_type_name
    "Book"
  end

  def root_node
    return nil if self.flat_book?
    @root_node ||= self.book_pages.first(:conditions => 'parent_id IS NULL AND name = "Root"') || self.create_root_node
  end

  def flat_book?
    self.book_type == 'flat'
  end

  def chapter_book?
    self.book_type == 'chapter'
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
    self.book_pages.create(:name => 'Root', :created_by_id => self.created_by_id)
  end

  # get a nested structure with 1 DB call
  def nested_pages
    if book_type == 'flat'
      self.book_pages
    else
      page_hash = {self.root_node.id => self.root_node}

      self.root_node.descendants.each do |nd|
        page_hash[nd.parent_id].child_cache << nd if page_hash[nd.parent_id]
        page_hash[nd.id] = nd
      end

      page_hash[root_node.id].child_cache
    end
  end
  
  def  first_page
    self.flat_book? ? self.book_pages.first : self.root_node.children[0]
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

  def export_book(args={}) 
    @pages = self.flat_book? ? self.book_pages : self.book_pages.find(:all, :conditions => "parent_id IS NOT NULL")

    tmp_path = "#{RAILS_ROOT}/tmp/export/"
    FileUtils.mkpath(tmp_path)
    filename  = tmp_path + DomainModel.active_domain_id.to_s + "_book_export.csv"

    CSV.open(filename,'w') do |writer|
      @pages.each_with_index do |page,idx|
        page.export_csv writer, :header => idx == 0
      end
    end

    domain_file = DomainFile.save_temporary_file filename, :name => sprintf("%s-%s_%s.%s",'Book'.t,self.name,Time.now.strftime("%Y_%m_%d"),'csv')

    { :filename => filename,
      :domain_file_id => domain_file.id,
      :entries => @pages.length,
      :type => 'text/csv',
      :completed => 1
    }
  end

  def import_book(filename, user, options={})
    filename = filename.filename if filename.is_a?(DomainFile)
    reader = CSV.open(filename, "r", ",")
    reader.shift
    reader.each do |row|
      BookPage.import_csv self, user, row, options
      yield 1, nil if block_given?
    end
  end

  def do_import(args={}) #:nodoc:
    file = DomainFile.find_by_id args[:domain_file_id]
    user = EndUser.find_by_id args[:user_id]

    return unless file

    results = Workling.return.get(args[:uid])

    count = 0
    CSV.open(file.filename, "r", ",").each do |row|
      count += 1 unless row.join.blank?
    end
    count = 1 if count < 1
    results[:entries] = count

    results[:initialized] = true
    results[:imported] = 0

    Workling.return.set(args[:uid], results)

    self.import_book(file.filename, user) do |imported, errors|
      results[:imported] += imported
      Workling.return.set(args[:uid], results) if (results[:imported] % 10) == 0
    end

    results
  end

end
