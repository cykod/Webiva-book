

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
editor_for :wiki_editor, :name => "Wiki Editor", :feature => 'book_page_wiki_editor',
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
    attributes :book_id => nil, :show_first_page => false, :enable_wiki => false, :edit_page_id => nil
    
    boolean_options :show_first_page, :enable_wiki
    page_options :edit_page_id

    canonical_paragraph "BookBook", :book_id

  end
  
  class WikiEditorOptions < HashModel
    attributes :book_id => nil, :auto_merge => false, :content_page_id => nil, :allow_create => false, :allow_auto_version => true
    page_options :content_page_id
    boolean_options :allow_auto_version
  end
end 
