

class Book::PageController < ParagraphController

  editor_header 'Book Paragraphs'
  
  editor_for :chapters, :name => "Book Chapters",
  :feature => 'menu',
  :inputs => { :book => [ [:book_id, 'Book ID',:path ]],
    :flat_chapter => [ [:chapter_id,' Chapter URL',:path ]]
  }
  editor_for :content, :name => "Book Content", :feature => 'book_page_content',
   :inputs => { :book => [ [:book_id, 'Book ID',:path ]],
    :flat_chapter => [ [:chapter_id,' Chapter URL',:path ]]
  }, 
  
  :outputs => [ [ :content_id, 'Content Identifier',:content]]

  class ChaptersOptions < HashModel
    attributes :book_id => 0, :levels => 0, :root_page_id => nil

    validates_presence_of :root_page_id
    page_options :root_page_id

    integer_options :levels

  end

  
  class ContentOptions < HashModel
    attributes :book_id => nil, :show_first_page => true

    boolean_options :show_first_page

    canonical_paragraph "BookBook", :book_id, :list_page_id => :node
  end

end
