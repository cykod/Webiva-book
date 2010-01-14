

class BookPage < DomainModel

  belongs_to :book_book

  acts_as_nested_set :scope => :book_book_id

  validates_presence_of :name

  validates_presence_of :book_book

  apply_content_filter(:body => :body_html)  do |page|
    { :filter => page.book_book.content_filter,
      :folder_id => page.book_book.image_folder_id
    }
  end

  before_save :create_url
  after_move :path_update
  after_save :force_resave_children

  content_node :container_type => 'BookBook', 
  :container_field => 'book_book_id',
  :except => Proc.new { |pg| pg.parent_id.blank? }, 
  :published => :published

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
    @back_page = :none if !@back_page || @back_page == :none ||  !@back_page.parent_id
    @back_page == :none ? nil : @back_page
  end
  
  protected

  def create_url
    logger.warn('Create URL')
    if  self.book_book.id_url?
      self.url = self.id.to_s
    else
      name_base = self.name.downcase.gsub(/[ _]+/,"-").gsub(/[^a-z+0-9\-]/,"")
     
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
      self.book_book.book_pages.find(:first,:conditions => ['`url`=? AND book_pages.id != ? ',name,self.id])
    else
      self.book_book.book_pages.find(:first,:conditions => ['`url`=? AND book_pages.id != ? AND parent_id=?',name,self.id,self.parent_id])
    end
  end

end
