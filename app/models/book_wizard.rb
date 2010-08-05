# Copyright (C) 2010 Cykod LLC.

class BookWizard < WizardModel

  def self.structure_wizard_handler_info
    {
      :name => "Add a Book to your Site",
      :description => 'This wizard will add an existing book to a url on your site.',
      :permit => "book_config",
      :url => self.wizard_url
    }
  end


  attributes :book_id => nil,
    :add_to_id => nil,
    :add_to_subpage => nil,
    :add_to_existing => nil,
    :wiki_page_url => 'edit',
    :opts => []

  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_format_of :wiki_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url', :allow_blank => true
  validates_presence_of :add_to_id

  validates_presence_of :book_id

  
  options_form(
               fld(:book_id, :select, :options => :book_select_options, :label => 'Book to Add'),
               fld(:add_to, :add_page_selector),
               fld(:opts, :check_boxes,
                   :options => [['Add a comments paragraph','comments'],
                                ['Add chapter list paragraph (menu)','chapters'],
                                ['Add a wiki edit paragraph','wiki']],
                   :label => 'Options', :separator => '<br/>'
                   ),
               fld(:wiki_page_url, :text_field, :label => "Wiki Edit Page", :size => 10)
               )

  def book_select_options
    BookBook.select_options_with_nil('Book')
  end

  def validate
    if self.add_to_existing.blank? && self.add_to_subpage.blank?
      self.errors.add(:add_to, "must have a subpage selected or add\n to existing must be checked")
    end
  end

  def can_run_wizard?
    BookBook.count > 0
  end

  def setup_url
    {:controller => '/book/manage', :action => 'book', :version => self.site_version_id}
  end

  def book
    @book ||= BookBook.find_by_id(self.book_id) if self.book_id
  end

  def set_defaults(params)
    self.book_id = params[:book_id].to_i
    self.add_to_subpage = SiteNode.generate_node_path(self.book.name) if self.book
  end

  def run_wizard
    base_node = SiteNode.find(self.add_to_id)

    if self.add_to_existing.blank?
      base_node = base_node.add_subpage(self.add_to_subpage)
    end

    base_node.new_revision do |book_revision|
      self.destroy_basic_paragraph(book_revision)

      book_para = book_revision.push_paragraph('/book/page','content',
                                               { :book_id => self.book_id,
                                                 :enable_wiki => self.opts.include?('wiki'),
                                                 :show_first_page => true,
                                                 :edit_page_id => nil
                                               }) do |para|
        para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)
      end

      if self.opts.include?('wiki')
        base_node.push_subpage(self.wiki_page_url) do |wiki_node, wiki_revision|
          self.destroy_basic_paragraph(wiki_revision)

          wiki_revision.push_paragraph('/book/page','wiki_editor',
                                       { :content_page_id => base_node.id,
                                         :book_id => self.book_id,
                                         :allow_auto_version => false,
                                         :allow_create => true
                                       }) do |para|
            para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)
          end

          book_para.data[:edit_page_id] = wiki_node.id
          book_para.save
        end
      end

      if self.opts.include?('comments')
        book_revision.push_paragraph('/feedback/comments','comments',
                                     { :show => -1,
                                       :allowed_to_post => 'all',
                                       :linked_to_type => 'connection',
                                       :captcha => false,
                                       :order => 'newest'
                                     }) do |para|
          para.add_paragraph_input!(:input,book_para,:content_id,:content_identifier)
        end
      end

      if self.opts.include?('chapters')
        book_revision.push_paragraph('/book/page','chapters',
                                     { :book_id => self.book_id,
                                       :root_page_id => base_node.id,
                                       :levels => 1
                                     }, :zone => 3) do |para|
          para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)
        end
      end
    end
  end
end

