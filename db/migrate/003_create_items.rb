class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items do |t|
      t.string :name
      t.timestamps :date_due
      t.integer :todo_list_id
      t.boolean :done
    end
  end

  def self.down
    drop_table :items
  end
end
