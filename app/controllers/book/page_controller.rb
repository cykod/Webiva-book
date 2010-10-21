

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
               },
    :outputs => [[:content_id, 'Content Identifier', :content]]

  editor_for :wiki_editor, :name => "Wiki Editor", :feature => 'book_page_wiki_editor',
    :inputs => { :book => [ [:book_id, 'Book ID',:path ]],
                 :flat_chapter => [ [:chapter_id,' Chapter URL',:path ]]
               },
    :outputs => [[:content_id, 'Content Identifier', :content]],
    :triggers => [['New Page', 'new_page'], ['Update Page', 'update_page']]

  class ChaptersOptions < HashModel
    attributes :book_id => nil, :levels => 1, :root_page_id => nil

    validates_presence_of :root_page_id

    page_options :root_page_id
    integer_options :levels

    options_form(
                 fld(:book_id, :select, :options => :book_options),
                 fld(:levels, :select, :options => (1..10).to_a),
                 fld(:root_page_id, :page_selector)
                 )

    def book_options
      [['--Use Page Connection--', nil]] + BookBook.select_options
    end
  end

  class ContentOptions < HashModel
    attributes :book_id => nil, :show_first_page => false, :enable_wiki => false, :edit_page_id => nil, :root_page_id => nil
    
    boolean_options :show_first_page, :enable_wiki
    page_options :edit_page_id, :root_page_id

    canonical_paragraph "BookBook", :book_id

    # root_page_id is set in the Book::PageRenderer for a content paragraph
    options_form(
                 fld(:book_id, :select, :options => :book_options),
                 fld(:show_first_page, :yes_no, :label => 'View First Page by Default'),
                 fld(:enable_wiki, :yes_no, :label => 'Enable wiki style editing'),
                 fld(:edit_page_id, :page_selector)
                 )

    def book_options
      [['--Use Page Connection--', nil]] + BookBook.select_options
    end

    def wiki?
      self.enable_wiki && self.edit_page_url
    end
  end

  class WikiEditorOptions < HashModel
    attributes :book_id => nil, :root_page_id => nil, :allow_create => false, :allow_auto_version => false

    validates_presence_of :root_page_id

    page_options :root_page_id
    boolean_options :allow_create, :allow_auto_version

    options_form(
                 fld('Page Display Control', :header),
                 fld(:book_id, :select, :options => :book_options),
                 fld(:root_page_id, :page_selector),
                 fld('User Content Control', :header),
                 fld(:allow_create, :yes_no, :label => 'Allow new pages', :description => 'This allows users to create new pages by entering a new page name after the book URL \nor clicking on link to a blank page.  No system notification is given to the user.'),
                 fld(:allow_auto_version, :yes_no, :label => 'Auto Publish', :description => 'If users are allowed to create pages, this option will say whether or not they are \nautomatically published.  If YES, the page will appear in the chapterlist as any other \npage would.  If NO, the page must be set to publish from the admin panel')
                 )

    def book_options
      [['--Use Page Connection--', nil]] + BookBook.select_options
    end

    def options_partial
      "/application/triggered_options_partial"
    end
  end
end 
