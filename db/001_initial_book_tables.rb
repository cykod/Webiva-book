class InitialBookTables < ActiveRecord::Migration
  def self.up
    create_table :book_books, :force => true do |t|
      t.string :name
      t.text :description
      t.integer :cover_file_id
      t.integer :thumb_file_id

      t.string :preview_wrapper

      t.integer :created_by_id

      t.integer :style_template_id
      t.string :book_type, :default => 'chapter' # chapter or flat
      t.string :url_scheme, :default => 'flat' # flat (url's are
      # unique, nested (url's are unique within a given parent),
      # id - urls don't show up
      t.string :content_filter, :default => 'markdown'
      t.integer :image_folder_id
      
      t.timestamps
    end

    create_table :book_pages, :force => true do |t|
      t.string :name
      t.text :description
      t.string :url
      t.string :path
      

      t.integer :book_book_id
      t.string :page_type, :default => 'page'

      t.boolean :published, :default => true
      
      t.text :body
      t.text :body_html
      
      # Awesome nested set fields
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.timestamps
      t.integer :updated_by_id
      t.integer :created_by_id
    end

    add_index :book_pages, [ :book_book_id, :lft, :rgt ], :name => 'page'

    create_table :book_page_versions, :force => true do |t|
      t.string :name

      t.integer :book_book_id
      t.integer :book_page_id

      t.text :body
      t.text :body_html

      t.timestamps
      t.integer :created_by_id
    end

    add_index :book_page_versions, [ :book_page_id, :created_at ], :name => 'page'

  end

  def self.down
    drop_table :book_books
    drop_table :book_pages
    drop_table :book_page_versions
  end
end
