

class Book::PageController < ParagraphController

  editor_header 'Book Paragraphs'
  
  editor_for :chapters, :name => "Chapters",
  :feature => 'menu',
  :inputs => { :book => [ [:book_id, 'Book ID',:path ]],
    :flat_chapter => [ [:chapter_id,' Chapter URL',:path ]]
  }
  editor_for :content, :name => "Content", :feature => 'book_page_content',
   :inputs => { :book => [ [:book_id, 'Book ID',:path ]],
    :flat_chapter => [ [:chapter_id,' Chapter URL',:path ]]
  }

  class ChapterOptions < HashModel
    attributes :book_id => 0, :levels => 0, :root_page_id => nil

    validates_presence_of :root_page_id
    page_options :root_page_id

    integer_options :levels

  end

  
  class ContentOptions < HashModel
    attributes :book_id => nil, :show_first_page => false

    boolean_options :show_first_page

    
  end

end
