

class BookPageVersion < DomainModel

  belongs_to :book_book

  acts_as_nested_set :scope => :book_book_id

  validates_presence_of :name

  validates_presence_of :book_book

  apply_content_filter(:body => :body_html)  do |page|
    { :filter => page.book_book.content_filter,
      :folder_id => page.book_book.image_folder_id, 
      :pre_filter => Proc.new { |code| page.replace_page_links(code)}
    }
  end

  set_table_name "book_page_versions"

  content_node :container_type => 'BookBook', :container_field => 'book_book_id',
  :except => Proc.new { |pg| pg.parent_id }, :published => :published

  def content_description(language)
    "Page in \"%s\" Book" / self.book_book.name
  end
  
  def replace_page_links(code)
    cd = code.gsub(/\[\[([^\]]+)\]\]/) do |mtch|
      linktext = $1
      newlink = $1.gsub(/[ _]+/,"-").downcase
      "<a href='#{newlink}'>#{linktext}</a>"
    end
    cd
  end
  
end
