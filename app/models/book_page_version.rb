

class BookPageVersion < DomainModel

  belongs_to :book_book
  belongs_to :book_page

  belongs_to :created_by, :class_name => 'EndUser', :foreign_key => :created_by_id
  validates_presence_of :name

  validates_presence_of :book_book


  
  def replace_page_links(code)
    cd = code.gsub(/\[\[([^\]]+)\]\]/) do |mtch|
      linktext = $1
      newlink = $1.gsub(/[ _]+/,"-").downcase
      "<a href='#{newlink}'>#{linktext}</a>"
    end
    cd
  end


  
end

