

class Book::PageFeature < ParagraphFeature


  feature :book_page_content, :default_feature => <<-FEATURE
   <cms:page>
    <table width='100%'>
    <tr>
    <td align='left' width='33%'><cms:back><cms:page_link>&lt; <cms:name/></cms:page_link></cms:back></td>
    <td align='center' width='33%'><cms:parent> <cms:page_link>^ <cms:name/></cms:page_link></cms:parent></td>
    <td align='right' width='33%'><cms:forward><cms:page_link><cms:name/></cms:page_link> &gt;</cms:forward></td>

    
    </tr>
    </table>
    <h1><cms:parent><cms:name/> : </cms:parent><cms:title/></h1>
    <div class='page_body'>
      <cms:body/>

    </div> 
    <div class='page_children'>
      <cms:children>
        <h2>Sectiossns:</h2>
        <ol>
          <cms:child>
             <li><cms:page_link><cms:name/></cms:page_link>
                 <cms:description><p><cms:value/></p></cms:description>
             </li>
          </cms:child>
        </ol>
      </cms:children>
    </div>
   </cms:page>
   <br><hr> <cms:edit_button/>

   <cms:no_page>
     Invalid Page
   </cms:no_page>

  FEATURE
  

  def book_page_content_feature(data)
    webiva_feature(:book_page_content,data) do |c|
      c.expansion_tag('page') { |t| t.locals.page = data[:page] }
      c.value_tag('level') { |t| t.locals.page.level }
      c.h_tag('page:title') { |t| t.locals.page.name }
      c.value_tag('page:body') { |t| t.locals.page.body_html  }
      c.value_tag('page:description') { |t| t.locals.page.description  }
      %w(back parent next previous forward).each do |pg|
        c.expansion_tag("page:#{pg}") { |t| t.locals.other_page = t.locals.page.send("#{pg}_page") }
        c.link_tag("page:#{pg}:page") { |t| data[:url].to_s + t.locals.other_page.path.to_s }
        c.h_tag("page:#{pg}:name") { |t| t.locals.other_page.name }
      end
      
      c.loop_tag('page:child','children') { |t| data[:page].children }
      c.link_tag('child:page') { |t| data[:url].to_s + t.locals.child.path.to_s }
      c.h_tag('child:name') { |t| t.locals.child.name }
      c.value_tag('child:description') { |t| t.locals.child.description }
      c.value_tag('child:body') { |t| t.locals.child.body_html }
      
      c.post_button_tag('edit_button',:button => 'Edit Page', :method => 'get') { |t| data[:edit_url] }


    end

  end
  

  feature :book_page_wiki_editor, :default_feature => <<-FEATURE
 
   <cms:page>
    <table width='100%'>
     <tr><cms:edit_page>
      <td>
          <cms:body/>
      </td>
     </tr>
     <tr>
      <td>
        <cms:submit/>        <cms:clear/>
       </cms:edit_page>
        
      </td>
     </tr>
    </table>
   </cms:page>
  FEATURE
  

  def book_page_wiki_editor_feature(data)
    webiva_feature(:book_page_wiki_editor,data) do |c|
      c.expansion_tag('page') { |t| t.locals.page = data[:page] }
      c.value_tag('level') { |t| t.locals.page.level }
      c.h_tag('page:title') { |t| t.locals.page.name }
      c.h_tag('page:body') { |t| t.locals.page.body  }
      c.h_tag('page:name') { |t| t.locals.page.name  }
      c.h_tag('page:id') { |t| t.locals.page.name  }

      
      
      c.value_tag('page:description') { |t| t.locals.page.description  }
      c.form_for_tag('edit_page', :page_versions) { |t|  t.locals.page }
      c.hidden_field('edit_page:ipaddress', :name=> :ipaddress, :value => @ipaddress )  
      
      
      c.field_tag('edit_page:body', :field => 'body',  :control => 'text_area', :rows => '20', :cols => '95' )

      c.button_tag('edit_page:submit', :name => 'commit', :value => 'Submit') 
      c.button_tag('edit_page:clear', :name => 'reset', :value => 'Start Over') 
    end
    
    
    
    
  end
  
end
