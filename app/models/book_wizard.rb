# Copyright (C) 2010 Cykod LLC.

class BookWizard < HashModel


  attributes :book_id => nil,
  :add_to_id=>nil,
  :add_to_subpage => nil,
  :add_to_existing => nil,
  :wiki_page_url => 'edit',
  :opts => []

  validates_format_of :add_to_subpage, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url'
  validates_format_of :wiki_page_url, :with => /^[a-zA-Z0-9\-_]+$/, :message => 'is an invalid url', :allow_blank => true
  validates_presence_of :add_to_id

  validates_presence_of :book_id

  
  def validate
    
    if self.add_to_existing.blank? && self.add_to_subpage.blank?
      self.errors.add(:add_to," must have a subpage selected or add\n to existing must be checked")
    end
  end

 def add_to_site!
    nd = SiteNode.find(self.add_to_id)

    if self.add_to_existing.blank?
      nd = nd.add_subpage(self.add_to_subpage)
    end 
     
     
   
   if self.opts.include?('wiki')


     sub = nd.add_subpage(self.wiki_page_url)
     sub.save

     book_revision = nd.page_revisions[0]
     wiki_revision = sub.page_revisions[0]


     book_para = book_revision.add_paragraph('/book/page','content',
                                             { 
                                               :book_id => self.book_id,
                                               :enable_wiki => true,
                                               :show_first_page => true,
                                               :edit_page_id => sub.id 
                                             }
                                             )
     book_para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)
     book_para.save

 


     wiki_para = wiki_revision.add_paragraph('/book/page','wiki_editor',
                                             { 
                                               :content_page_id => nd.id,
                                               :book_id => self.book_id,
                                               :allow_auto_version => false,
                                               :allow_create => true
                                             }
                                             )
     
     wiki_para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)

     wiki_para.save
    else
     book_revision = nd.page_revisions[0]
     
     book_para = book_revision.add_paragraph('/book/page','content',
                                             { 
                                               :book_id => self.book_id,
                                               :enable_wiki => false,
                                               :show_first_page => true,
                                             }
                                             )
     book_para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)

     book_para.save
     
   
   
   end
     if self.opts.include?('comments')
       
       comments_paragraph = book_revision.add_paragraph('/feedback/comments','comments',
                                                        { 
                                                          :show => -1,
                                                          :allowed_to_post => 'all',
                                                          :linked_to_type => 'connection',
                                                          :captcha => false,
                                                          :order => 'newest'
                                                        }
                                                        )
       comments_paragraph.save
       comments_paragraph.add_paragraph_input!(:input,book_para,:content_id,:content_identifier)
     end
   
   if self.opts.include?('chapters')
     chap_para = book_revision.add_paragraph('/book/page','chapters',
                                             { 
                                               :book_id => self.book_id,
                                               :root_page_id => nd.id,
                                               :levels => 1
                                             },
                                             :zone => 3
                                             )
     chap_para.save
     chap_para.add_page_input(:flat_chapter,:page_arg_0,:chapter_id)

   end
   
   
   
 end
 
end

