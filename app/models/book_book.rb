

class BookBook < DomainModel

  has_domain_file :cover_file_id
  has_domain_file :thumb_file_Id

  has_many :book_pages, :dependent => :destroy, :order => 'book_pages.name'

  after_create :create_root_node


  has_options :book_type, [ [ 'Chapter Based', 'chapter'],
                            [ 'Flat','flat' ]
                          ]

  belongs_to :style_template, :class_name => 'SiteTemplate', :foreign_key => 'style_template_id'
  
  has_options :url_scheme, [ ['Flat','flat'],['Nested','nested'],['ID','id']]

  validates_presence_of :name
  validates_format_of :preview_wrapper, :allow_blank => true, :with => /^(\.|\#)/
  attr_protected :url_scheme, :book_type

  content_node_type :book, "BookPage", :content_name => :name,:title_field => :name, :url_field => :url

  
  def content_admin_url(book_page_id)
    {  :controller => '/book/manage', :action => 'edit', :path => [ self.id, book_page_id ],
       :title => 'Edit Book Page'.t}
  end

  def content_type_name
    "Book"
  end

  def root_node
    @root_node ||= self.book_pages.find(:first,:conditions => 'parent_id IS NULL', :order => 'book_pages.id')
  # @root_node ||= self.book_pages.find(:first,:order => 'name')

  end

  def flat_url?
    self.url_scheme == 'flat'
  end

  def id_url?
    self.url_scheme == 'id'
  end
  
  
  def create_root_node
    self.book_pages.create(:name => 'Root') unless book_type == 'flat'
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

end
