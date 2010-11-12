

class Book::PageFeature < ParagraphFeature

  include BookHelper

  feature :book_page_content, :default_feature => <<-FEATURE
   <cms:page>
    <table width='100%'>
    <tr>
    <td align='left' width='33%'><cms:back><cms:page_link>&lt; <cms:name/></cms:page_link></cms:back></td>
    <td align='center' width='33%'><cms:parent> <cms:page_link>^ <cms:name/></cms:page_link></cms:parent></td>
    <td align='right' width='33%'><cms:forward><cms:page_link><cms:name/></cms:page_link> &gt;</cms:forward></td>
    </tr>
    </table>
    
    <cms:notice><div class='notice'><cms:value/></div></cms:notice>
    <h1><cms:parent><cms:name/> : </cms:parent><cms:title/></h1>
    <div class='page_body'>
      <cms:body/>
    </div>

    <cms:children>
      <div class='page_children'>
        <h2>Sections:</h2>
        <ol>
          <cms:child>
             <li><cms:page_link><cms:name/></cms:page_link>
                 <cms:description><p><cms:value/></p></cms:description>
             </li>
          </cms:child>
        </ol>
      </div>
    </cms:children>

    <cms:wiki_enabled>
      <hr/>
      <cms:edit_link>Edit</cms:edit_link>
    </cms:wiki_enabled>
   </cms:page>

   <cms:no_page>
     <cms:wiki_enabled>
       <div class='page_body'>
         <cms:create_link>This page is blank, click to add to it.</cms:create_link>
       </div>
     </cms:wiki_enabled>
   </cms:no_page>
  FEATURE

  def book_page_content_feature(data)
    webiva_feature(:book_page_content,data) do |c|
      c.expansion_tag('page') { |t| t.locals.page = data[:page] }
      page_details_tags(data, c)
    
      c.expansion_tag('book') { |t| t.locals.book = data[:book] }
      book_details_tags(data, c)

      c.expansion_tag('logged_in') { |t| myself.id }
      c.expansion_tag('wiki_enabled') { |t| data[:options].wiki? }
      c.link_tag('create'){ |t| edit_url(data[:options], data[:book], data[:missing_page_url]) }
      c.link_tag('page:edit') { |t| edit_url(data[:options], data[:book], data[:page]) }
      
      c.h_tag('page:notice') { |t| data[:notice] }
    end
  end

  feature :book_page_wiki_editor, :default_feature => <<-FEATURE
  <cms:page>
    <h1><span>Edit</span> <cms:parent><cms:name/> : </cms:parent><cms:title/></h1>
  </cms:page>

  <cms:no_page>
    <h1><span>Add a new page</span></h1>
  </cms:no_page>

  <cms:form>
    <cms:no_page>
      <cms:name/><br/>
    </cms:no_page>
    <cms:body/><br/>
    <cms:submit/>
  </cms:form>
  FEATURE

  def book_page_wiki_editor_feature(data)
    webiva_feature(:book_page_wiki_editor,data) do |c|
      c.expansion_tag('page') { |t| t.locals.page = data[:page] if data[:page] && data[:page].id }
      page_details_tags(data, c)

      c.expansion_tag('book') { |t| t.locals.book = data[:book] }
      book_details_tags(data, c)

      c.expansion_tag('logged_in') { |t| myself.id }

      c.form_for_tag('form', :page) { |t| data[:page] }
        c.field_tag('form:name', :field => 'name')
        c.field_tag('form:body', :field => 'body',  :control => 'text_area')
        c.button_tag('form:submit', :name => 'commit', :value => 'Submit') 
        c.button_tag('form:reset', :name => 'reset', :value => 'Reset', :control => 'reset') 
    end
  end

  def book_details_tags(data, c)
    c.h_tag('book:title') { |t| t.locals.book.name }
    c.h_tag('book:description') { |t| t.locals.book.description }
    c.image_tag('book:cover') { |t| t.locals.book.cover_file }
    c.image_tag('book:thumb') { |t| t.locals.book.thumb_file }
  end

  def page_details_tags(data, c)
    c.h_tag('page:title') { |t| t.locals.page.name }
    c.value_tag('page:body') { |t| t.locals.page.body_html  }
    c.link_tag("page:return") { |t| content_url(data[:options], data[:book], t.locals.page) }
    c.link_tag("page:page") { |t| content_url(data[:options], data[:book], t.locals.page) }
    
    %w(back parent next previous forward).each do |dir|
      c.expansion_tag("page:#{dir}") { |t| t.locals.other_page = t.locals.page.send("#{dir}_page") }
      c.link_tag("page:#{dir}:page") { |t| content_url(data[:options], data[:book], t.locals.other_page) }
      c.h_tag("page:#{dir}:name") { |t| t.locals.other_page.name }
    end
    
    c.loop_tag('page:child','children') { |t| t.locals.page.children.find(:all, :conditions => {:published => true}) }
    c.link_tag('child:page') { |t| content_url(data[:options], data[:book], t.locals.child) }
    c.h_tag('child:name') { |t| t.locals.child.name }
    c.h_tag('child:description') { |t| t.locals.child.description }
  end
end
