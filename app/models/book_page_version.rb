
class BookPageVersion < DomainModel
  belongs_to :book_book
  belongs_to :book_page
  belongs_to :created_by, :class_name => 'EndUser', :foreign_key => :created_by_id

  validates_presence_of :name
  validates_presence_of :book_page_id
  validates_presence_of :book_book_id

  named_scope :latest_revision, :conditions => {:version_type => 'admin editor'}, :order => 'id DESC', :limit => 1

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
end

